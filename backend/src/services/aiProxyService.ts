import { env } from '../config/env';
import { z } from 'zod';

const roleSchema = z.enum(['system', 'user', 'assistant']);

const chatCompletionsSchema = z.object({
    messages: z.array(
        z.object({
            role: roleSchema,
            content: z.string(),
        })
    ),
    max_tokens: z.coerce.number().int().min(1).max(1400).optional(),
    temperature: z.coerce.number().min(0).max(2).optional(),
    top_p: z.coerce.number().min(0).max(1).optional(),
    presence_penalty: z.coerce.number().min(-2).max(2).optional(),
    frequency_penalty: z.coerce.number().min(-2).max(2).optional(),
    response_format: z
        .object({
            type: z.literal('json_object'),
        })
        .optional(),
});

function normalizeBaseUrl(input: string): string {
    const trimmed = input.trim().replace(/\/+$/, '');
    if (trimmed.endsWith('/v1')) return trimmed.slice(0, -3);
    return trimmed;
}

const limiter = new Map<string, { windowStart: number; count: number }>();

export function checkAiRateLimit(key: string): { ok: true } | { ok: false; retryAfterMs: number } {
    const now = Date.now();
    const windowMs = env.AI_RATE_LIMIT_WINDOW_MS;
    const max = env.AI_RATE_LIMIT_MAX;
    const current = limiter.get(key);
    if (!current || now - current.windowStart >= windowMs) {
        limiter.set(key, { windowStart: now, count: 1 });
        return { ok: true };
    }
    if (current.count >= max) {
        return { ok: false, retryAfterMs: windowMs - (now - current.windowStart) };
    }
    current.count += 1;
    limiter.set(key, current);
    return { ok: true };
}

export async function proxyChatCompletions(body: unknown): Promise<{ status: number; data: unknown }> {
    const parsed = chatCompletionsSchema.safeParse(body);
    if (!parsed.success) {
        return { status: 400, data: { error: 'Invalid request body', details: parsed.error.issues } };
    }

    const apiKey = (env.AI_API_KEY ?? '').trim();
    if (!apiKey) {
        return { status: 501, data: { error: 'AI is not configured' } };
    }

    const baseUrl = normalizeBaseUrl(env.AI_BASE_URL);
    const endpoint = `${baseUrl}/v1/chat/completions`;

    const upstreamBody: Record<string, unknown> = {
        model: env.AI_MODEL,
        messages: parsed.data.messages,
        max_tokens: parsed.data.max_tokens ?? 220,
        temperature: parsed.data.temperature ?? 0.85,
        top_p: parsed.data.top_p ?? 0.9,
        presence_penalty: parsed.data.presence_penalty ?? 0.35,
        frequency_penalty: parsed.data.frequency_penalty ?? 0.35,
    };
    if (parsed.data.response_format) {
        upstreamBody.response_format = parsed.data.response_format;
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), env.AI_TIMEOUT_MS);
    try {
        const resp = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${apiKey}`,
            },
            body: JSON.stringify(upstreamBody),
            signal: controller.signal,
        });

        const text = await resp.text();
        const data = (() => {
            try {
                return JSON.parse(text);
            } catch (_) {
                return { raw: text };
            }
        })();

        if (!resp.ok) {
            if (resp.status === 401 || resp.status === 403) {
                return { status: 502, data: { error: 'AI upstream auth failed' } };
            }
            return { status: 502, data: { error: 'AI upstream error', upstreamStatus: resp.status, data } };
        }

        return { status: 200, data };
    } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        return { status: 502, data: { error: 'AI upstream connection failed', message } };
    } finally {
        clearTimeout(timeout);
    }
}

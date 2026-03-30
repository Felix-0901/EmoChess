import { prisma } from '../db/prisma';
import { proxyChatCompletions } from './aiProxyService';

function normalizeLang(input: unknown): 'en' | 'zh' {
    const v = typeof input === 'string' ? input.trim().toLowerCase() : '';
    return v === 'zh' ? 'zh' : 'en';
}

function systemPrompt(lang: 'en' | 'zh'): string {
    if (lang === 'zh') {
        return `你是一位「情緒棋局」的陪伴分析助理，讀者是家長/治療師（非當事小朋友）。請根據提供的棋局、聊天、情緒變化與回合互動，產生一份可讀性高、溫和且不下診斷的分析報告。

規則：
- 不要進行醫療診斷或貼標籤，不要把孩子描述成「有問題」
- 以支持與觀察為主，給可執行的小建議
- 嚴格輸出 JSON object（不要 markdown、不要多餘文字）
- 回覆以「文字陳述」為主，針對棋局內容做分析呈現
- 允許 analysis_report 更詳細，但請避免過度冗長導致 JSON 被截斷
- emotion_overview 與 recommendations 也使用文字段落（不要輸出 key-value 或列表物件）
- 嚴格只輸出下列四個欄位（不要多其他 key）

輸出 JSON 格式：
{
  "analysis_report": "分析報告（可稍長，分段文字即可）",
  "emotion_overview": "情緒概要（文字陳述，描述整體變化與可能觸發）",
  "recommendations": "建議（文字陳述，具體可行，對應這局的狀況）",
  "disclaimer": "提醒：本報告為輔助觀察，不是診斷。"
}`;
    }

    return `You are an emotion-aware gameplay report assistant. The audience is parents/therapists (not the child). Based on the provided chess game, chat, emotion events, and structured conversation rounds, write a gentle, actionable analysis report. No medical diagnosis.

Rules:
- No medical diagnosis or labels
- Be supportive and observation-based
- Output MUST be strict JSON object only (no markdown)
- Use narrative text based on this specific game
- analysis_report can be more detailed, but avoid making it so long that JSON gets truncated
- emotion_overview and recommendations must be narrative text (not key-value objects or lists of objects)
- Output ONLY the four keys below (no extra keys)

JSON shape:
{
  "analysis_report": "Analysis report (can be longer; paragraph text is fine)",
  "emotion_overview": "Emotion overview (narrative text)",
  "recommendations": "Recommendations (narrative text; actionable; tied to this game)",
  "disclaimer": "This report supports observation, not diagnosis."
}`;
}

function userPrompt(payload: any, lang: 'en' | 'zh'): string {
    const json = JSON.stringify(payload);
    if (lang === 'zh') {
        return `以下是單局資料（JSON），請依照 system 指示輸出報告：\n${json}`;
    }
    return `Here is the single-game payload (JSON). Follow system instructions and output the report:\n${json}`;
}

function buildPayload(record: any) {
    const moves = Array.isArray(record.moves) ? record.moves : [];
    const chats = Array.isArray(record.chatHistory) ? record.chatHistory : [];
    const emotions = Array.isArray(record.emotionLog) ? record.emotionLog : [];
    const rounds = Array.isArray(record.conversationRounds) ? record.conversationRounds : [];

    const emotionCounts: Record<string, number> = {};
    for (const e of emotions) {
        const key = typeof e?.emotion === 'string' ? e.emotion : 'unknown';
        emotionCounts[key] = (emotionCounts[key] ?? 0) + 1;
    }

    const triggerCounts: Record<string, number> = {};
    for (const e of emotions) {
        const key = typeof e?.trigger === 'string' ? e.trigger : 'unknown';
        triggerCounts[key] = (triggerCounts[key] ?? 0) + 1;
    }

    return {
        game: {
            id: record.id,
            sessionId: record.sessionId,
            startTime: record.startTime,
            endTime: record.endTime,
            initialEmotion: record.initialEmotion,
            result: record.result,
            durationSeconds: record.durationSeconds ?? null,
        },
        stats: {
            moves: moves.length,
            chats: chats.length,
            emotion_events: emotions.length,
            rounds: rounds.length,
            duration_seconds: record.durationSeconds ?? 0,
        },
        emotion_distribution: emotionCounts,
        trigger_distribution: triggerCounts,
        recent_moves: moves.slice(-12).map((m: any) => ({
            moveNumber: m.moveNumber,
            san: m.san,
            player: m.player,
            isCapture: typeof m?.san === 'string' ? m.san.includes('x') : undefined,
        })),
        recent_chat: chats.slice(-18).map((c: any) => ({
            sender: c.sender,
            message: c.message,
            userChoice: c.userChoice,
            aiResponse: c.aiResponse,
            moveNumber: c.moveNumber,
            roundId: c.roundId,
        })),
        recent_emotions: emotions.slice(-24).map((e: any) => ({
            timestamp: e.timestamp,
            emotion: e.emotion,
            moveNumber: e.moveNumber,
            trigger: e.trigger,
        })),
        recent_rounds: rounds.slice(-12).map((r: any) => ({
            roundId: r.roundId,
            timestamp: r.timestamp,
            moveNumber: r.moveNumber,
            emotion: r.emotion,
            trigger: r.trigger,
            intent: r.intent,
            angleKey: r.angleKey,
            aiQuestion: r.aiQuestion,
            choices: r.choices,
            selectedChoice: r.selectedChoice,
            aiReply: r.aiReply,
        })),
    };
}

function extractJsonObject(text: string): any | null {
    const trimmed = text.trim();
    if (!trimmed) return null;

    function stripCodeFences(input: string): string {
        let s = input.trim();
        if (!s.includes('```')) return s;
        s = s.replace(/```(?:json)?/gi, '```');
        const start = s.indexOf('```');
        const end = s.lastIndexOf('```');
        if (start >= 0 && end > start) {
            return s.slice(start + 3, end).trim();
        }
        return s.replace(/```/g, '').trim();
    }

    function normalizeForJson(input: string): string {
        let s = input.trim();
        s = s
            .replace(/[“”]/g, '"')
            .replace(/[‘’]/g, "'")
            .replace(/\uFEFF/g, '');
        s = s.replace(/,\s*([}\]])/g, '$1');
        return s;
    }

    function tryParseObject(input: string): any | null {
        const s = normalizeForJson(stripCodeFences(input));
        try {
            const parsed = JSON.parse(s);
            if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) return parsed;
            if (Array.isArray(parsed)) {
                const firstObj = parsed.find((x) => x && typeof x === 'object' && !Array.isArray(x));
                return firstObj ?? null;
            }
        } catch (_) {}
        return null;
    }

    const direct = tryParseObject(trimmed);
    if (direct) return direct;

    const braceStart = trimmed.indexOf('{');
    const braceEnd = trimmed.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
        const slice = trimmed.slice(braceStart, braceEnd + 1);
        const sliced = tryParseObject(slice);
        if (sliced) return sliced;
    }

    const bracketStart = trimmed.indexOf('[');
    const bracketEnd = trimmed.lastIndexOf(']');
    if (bracketStart >= 0 && bracketEnd > bracketStart) {
        const slice = trimmed.slice(bracketStart, bracketEnd + 1);
        const sliced = tryParseObject(slice);
        if (sliced) return sliced;
    }

    return null;
}

function extractReportContent(data: any): string | null {
    const content = data?.choices?.[0]?.message?.content;
    if (typeof content === 'string') return content;
    if (Array.isArray(content)) {
        const joined = content
            .map((part: any) => {
                if (typeof part === 'string') return part;
                if (!part || typeof part !== 'object') return '';
                const text = part.text ?? part.content ?? part.value;
                if (typeof text === 'string') return text;
                const nested = part.text?.value ?? part.content?.text;
                if (typeof nested === 'string') return nested;
                return '';
            })
            .join('');
        return joined.trim().length ? joined : null;
    }
    if (content && typeof content === 'object') {
        const text = (content as any).text ?? (content as any).value;
        if (typeof text === 'string') return text;
    }
    const legacy = data?.choices?.[0]?.text;
    if (typeof legacy === 'string') return legacy;
    const outputText = data?.output_text;
    if (typeof outputText === 'string') return outputText;
    const output = data?.output;
    if (Array.isArray(output)) {
        const joined = output
            .map((item: any) => {
                const contents = item?.content;
                if (!Array.isArray(contents)) return '';
                return contents
                    .map((c: any) => {
                        const t = c?.text ?? c?.value ?? c?.content;
                        if (typeof t === 'string') return t;
                        const nested = c?.text?.value;
                        if (typeof nested === 'string') return nested;
                        return '';
                    })
                    .join('');
            })
            .join('\n');
        if (joined.trim().length) return joined;
    }
    const raw = data?.raw;
    if (typeof raw === 'string') return raw;
    return null;
}

function isNewReportFormat(reportJson: unknown): boolean {
    if (!reportJson || typeof reportJson !== 'object' || Array.isArray(reportJson)) return false;
    const r = reportJson as any;
    return (
        typeof r.analysis_report === 'string' &&
        r.analysis_report.trim().length > 0 &&
        typeof r.emotion_overview === 'string' &&
        r.emotion_overview.trim().length > 0 &&
        typeof r.recommendations === 'string' &&
        r.recommendations.trim().length > 0 &&
        typeof r.disclaimer === 'string' &&
        r.disclaimer.trim().length > 0
    );
}

export async function getOrCreateGameReport(userId: string, gameId: string, language: unknown) {
    const lang = normalizeLang(language);

    const existing = await prisma.aiReport.findUnique({
        where: { userId_gameRecordId_language: { userId, gameRecordId: gameId, language: lang } },
    });
    if (existing && isNewReportFormat(existing.reportJson)) return existing;

    const record = await prisma.gameRecord.findFirst({
        where: { id: gameId, userId },
        include: {
            moves: { orderBy: { moveNumber: 'asc' } },
            chatHistory: { orderBy: { timestamp: 'asc' } },
            emotionLog: { orderBy: { timestamp: 'asc' } },
            conversationRounds: { orderBy: { timestamp: 'asc' } },
        },
    });

    if (!record) {
        const err = new Error('RECORD_NOT_FOUND');
        (err as any).code = 'RECORD_NOT_FOUND';
        throw err;
    }

    const payload = buildPayload(record);

    const result = await proxyChatCompletions({
        messages: [
            { role: 'system', content: systemPrompt(lang) },
            { role: 'user', content: userPrompt(payload, lang) },
        ],
        max_tokens: 1200,
        temperature: 0.55,
        top_p: 0.9,
        presence_penalty: 0.15,
        frequency_penalty: 0.15,
        response_format: { type: 'json_object' },
    });

    if (result.status !== 200) {
        const err = new Error('AI_REPORT_FAILED');
        (err as any).detail = result.data;
        throw err;
    }

    const data: any = result.data as any;
    const content = extractReportContent(data);
    if (typeof content !== 'string' || content.trim().length === 0) {
        const err = new Error('AI_REPORT_BAD_RESPONSE');
        (err as any).detail = data;
        throw err;
    }

    const json = extractJsonObject(content);
    if (!json || typeof json !== 'object') {
        const err = new Error('AI_REPORT_NOT_JSON');
        (err as any).raw = content;
        throw err;
    }

    if (existing) {
        return prisma.aiReport.update({
            where: { id: existing.id },
            data: { reportJson: json },
        });
    }

    return prisma.aiReport.create({
        data: { userId, gameRecordId: gameId, language: lang, reportJson: json },
    });
}

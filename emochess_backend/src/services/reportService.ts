import { prisma } from '../db/prisma';
import { proxyChatCompletions } from './aiProxyService';

function normalizeLang(input: unknown): 'en' | 'zh' {
    const v = typeof input === 'string' ? input.trim().toLowerCase() : '';
    return v === 'zh' ? 'zh' : 'en';
}

function systemPrompt(lang: 'en' | 'zh'): string {
    if (lang === 'zh') {
        return `你是一位「情緒棋局」的陪伴分析助理，讀者是家長/治療師（非當事小朋友）。請根據提供的棋局、聊天、情緒變化與回合互動，產生一份可讀性高、溫和且不下診斷的摘要報告。

規則：
- 不要進行醫療診斷或貼標籤，不要把孩子描述成「有問題」
- 以支持與觀察為主，給可執行的小建議
- 嚴格輸出 JSON object（不要 markdown、不要多餘文字）

輸出 JSON 格式：
{
  "summary": "一段摘要（2-4 句）",
  "emotion_overview": { "start": "happy|neutral|anxious|frustrated", "end": "...", "dominant": "...", "notes": "..." },
  "highlights": [
    { "moment": "簡短描述", "emotion": "happy|neutral|anxious|frustrated", "trigger": "check|capture|user_input|...|unknown", "evidence": "引用或描述依據" }
  ],
  "conversation_patterns": [
    { "pattern": "模式名稱", "evidence": "例子", "why_it_matters": "為什麼重要" }
  ],
  "recommendations": [
    { "title": "建議標題", "how": "如何做（具體）", "when": "什麼情境使用" }
  ],
  "stats": { "moves": 0, "chats": 0, "emotion_events": 0, "rounds": 0, "duration_seconds": 0 },
  "disclaimer": "提醒：本報告為輔助觀察，不是診斷。"
}`;
    }

    return `You are an emotion-aware gameplay report assistant. The audience is parents/therapists (not the child). Based on the provided chess game, chat, emotion events, and structured conversation rounds, write a gentle, actionable report. No medical diagnosis.

Rules:
- No medical diagnosis or labels
- Be supportive and observation-based
- Output MUST be strict JSON object only (no markdown)

JSON shape:
{
  "summary": "2-4 sentences",
  "emotion_overview": { "start": "happy|neutral|anxious|frustrated", "end": "...", "dominant": "...", "notes": "..." },
  "highlights": [
    { "moment": "short description", "emotion": "happy|neutral|anxious|frustrated", "trigger": "check|capture|user_input|...|unknown", "evidence": "quote or description" }
  ],
  "conversation_patterns": [
    { "pattern": "pattern name", "evidence": "example", "why_it_matters": "why it matters" }
  ],
  "recommendations": [
    { "title": "title", "how": "specific steps", "when": "when to use" }
  ],
  "stats": { "moves": 0, "chats": 0, "emotion_events": 0, "rounds": 0, "duration_seconds": 0 },
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
    try {
        return JSON.parse(trimmed);
    } catch (_) {}

    const start = trimmed.indexOf('{');
    const end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
        const slice = trimmed.slice(start, end + 1);
        try {
            return JSON.parse(slice);
        } catch (_) {}
    }
    return null;
}

export async function getOrCreateGameReport(userId: string, gameId: string, language: unknown) {
    const lang = normalizeLang(language);

    const existing = await prisma.aiReport.findUnique({
        where: { userId_gameRecordId_language: { userId, gameRecordId: gameId, language: lang } },
    });
    if (existing) return existing;

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
        max_tokens: 380,
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
    const content = data?.choices?.[0]?.message?.content;
    if (typeof content !== 'string') {
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

    return prisma.aiReport.create({
        data: {
            userId,
            gameRecordId: gameId,
            language: lang,
            reportJson: json,
        },
    });
}


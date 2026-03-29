import { z } from 'zod';
import { calculateGameXp, calculateLevel } from './statsService';
import { prisma } from '../db/prisma';

// ─── 驗證 Schema ────────────────────────────────────

const moveRecordSchema = z.object({
    moveNumber: z.number(),
    san: z.string(),
    player: z.string(),
    timestamp: z.string(),
    preFen: z.string().optional(),
    postFen: z.string().optional(),
});

const chatRecordSchema = z.object({
    timestamp: z.string(),
    sender: z.string(),
    message: z.string(),
    userChoice: z.string().optional(),
    aiResponse: z.string().optional(),
    moveNumber: z.number().optional(),
    whitePreFen: z.string().optional(),
    whitePostFen: z.string().optional(),
    blackPostFen: z.string().optional(),
    roundId: z.string().optional(),
});

const emotionRecordSchema = z.object({
    timestamp: z.string(),
    emotion: z.string(),
    moveNumber: z.number().optional(),
    trigger: z.string().optional(),
});

export const createGameSchema = z.object({
    sessionId: z.string(),
    startTime: z.string(),
    endTime: z.string().optional(),
    initialEmotion: z.string(),
    result: z.string().optional(),
    durationSeconds: z.number().optional(),
    moves: z.array(moveRecordSchema).optional().default([]),
    chatHistory: z.array(chatRecordSchema).optional().default([]),
    emotionLog: z.array(emotionRecordSchema).optional().default([]),
});

// ─── 服務函式 ────────────────────────────────────────

/**
 * 上傳完整遊戲記錄（含 moves、chat、emotions）
 */
export async function createGameRecord(
    userId: string,
    data: z.infer<typeof createGameSchema>
) {
    const gameRecord = await prisma.gameRecord.create({
        data: {
            userId,
            sessionId: data.sessionId,
            startTime: new Date(data.startTime),
            endTime: data.endTime ? new Date(data.endTime) : null,
            initialEmotion: data.initialEmotion,
            result: data.result,
            durationSeconds: data.durationSeconds,
            moves: {
                create: data.moves.map((m) => ({
                    moveNumber: m.moveNumber,
                    san: m.san,
                    player: m.player,
                    timestamp: new Date(m.timestamp),
                    preFen: m.preFen,
                    postFen: m.postFen,
                })),
            },
            chatHistory: {
                create: data.chatHistory.map((c) => ({
                    timestamp: new Date(c.timestamp),
                    sender: c.sender,
                    message: c.message,
                    userChoice: c.userChoice,
                    aiResponse: c.aiResponse,
                    moveNumber: c.moveNumber,
                    whitePreFen: c.whitePreFen,
                    whitePostFen: c.whitePostFen,
                    blackPostFen: c.blackPostFen,
                    roundId: c.roundId,
                })),
            },
            emotionLog: {
                create: data.emotionLog.map((e) => ({
                    timestamp: new Date(e.timestamp),
                    emotion: e.emotion,
                    moveNumber: e.moveNumber,
                    trigger: e.trigger,
                })),
            },
        },
        include: {
            moves: true,
            chatHistory: true,
            emotionLog: true,
        },
    });

    // ─── 更新用戶 XP 和統計 ────────────────────────
    const xpEarned = calculateGameXp(data.result);
    if (xpEarned > 0) {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { totalXp: true },
        });

        const newTotalXp = (user?.totalXp ?? 0) + xpEarned;
        const newLevel = calculateLevel(newTotalXp);

        const isWin =
            data.result === 'white_wins' || data.result === 'black_wins';

        await prisma.user.update({
            where: { id: userId },
            data: {
                totalXp: newTotalXp,
                level: newLevel,
                gamesPlayed: { increment: 1 },
                ...(isWin ? { gamesWon: { increment: 1 } } : {}),
            },
        });
    }

    return gameRecord;
}

/**
 * 取得用戶所有遊戲記錄（列表）
 */
export async function getGameRecords(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [records, total] = await Promise.all([
        prisma.gameRecord.findMany({
            where: { userId },
            orderBy: { startTime: 'desc' },
            skip,
            take: limit,
            include: {
                _count: {
                    select: {
                        moves: true,
                        chatHistory: true,
                        emotionLog: true,
                    },
                },
            },
        }),
        prisma.gameRecord.count({ where: { userId } }),
    ]);

    return {
        records: records.map((r) => ({
            id: r.id,
            sessionId: r.sessionId,
            startTime: r.startTime,
            endTime: r.endTime,
            initialEmotion: r.initialEmotion,
            result: r.result,
            durationSeconds: r.durationSeconds,
            movesCount: r._count.moves,
            chatCount: r._count.chatHistory,
            emotionCount: r._count.emotionLog,
        })),
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
        },
    };
}

/**
 * 取得單筆遊戲記錄詳情
 */
export async function getGameRecordById(userId: string, gameId: string) {
    const record = await prisma.gameRecord.findFirst({
        where: { id: gameId, userId },
        include: {
            moves: { orderBy: { moveNumber: 'asc' } },
            chatHistory: { orderBy: { timestamp: 'asc' } },
            emotionLog: { orderBy: { timestamp: 'asc' } },
        },
    });

    if (!record) {
        throw new Error('RECORD_NOT_FOUND');
    }

    return record;
}

/**
 * 刪除遊戲記錄
 */
export async function deleteGameRecord(userId: string, gameId: string) {
    const record = await prisma.gameRecord.findFirst({
        where: { id: gameId, userId },
    });

    if (!record) {
        throw new Error('RECORD_NOT_FOUND');
    }

    await prisma.gameRecord.delete({
        where: { id: gameId },
    });

    return { success: true };
}

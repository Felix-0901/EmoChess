import { prisma } from '../db/prisma';

/**
 * 取得用戶情緒統計摘要
 */
export async function getEmotionSummary(userId: string, lastN = 10) {
    // 取得最近 N 場遊戲的情緒記錄
    const recentGames = await prisma.gameRecord.findMany({
        where: { userId },
        orderBy: { startTime: 'desc' },
        take: lastN,
        select: {
            id: true,
            sessionId: true,
            startTime: true,
            initialEmotion: true,
            result: true,
            durationSeconds: true,
            emotionLog: {
                orderBy: { timestamp: 'asc' },
                select: {
                    emotion: true,
                    timestamp: true,
                    moveNumber: true,
                    trigger: true,
                },
            },
        },
    });

    // 統計各情緒出現次數
    const emotionCounts: Record<string, number> = {};
    const triggerCounts: Record<string, number> = {};
    let totalEmotionRecords = 0;

    for (const game of recentGames) {
        for (const emo of game.emotionLog) {
            emotionCounts[emo.emotion] = (emotionCounts[emo.emotion] || 0) + 1;
            if (emo.trigger) {
                triggerCounts[emo.trigger] = (triggerCounts[emo.trigger] || 0) + 1;
            }
            totalEmotionRecords++;
        }
    }

    // 計算初始情緒分布
    const initialEmotionCounts: Record<string, number> = {};
    for (const game of recentGames) {
        initialEmotionCounts[game.initialEmotion] =
            (initialEmotionCounts[game.initialEmotion] || 0) + 1;
    }

    // 計算勝負統計
    const resultCounts: Record<string, number> = {};
    for (const game of recentGames) {
        const result = game.result || 'incomplete';
        resultCounts[result] = (resultCounts[result] || 0) + 1;
    }

    // 平均遊戲時長
    const gameDurations = recentGames
        .filter((g) => g.durationSeconds != null)
        .map((g) => g.durationSeconds!);

    const avgDuration =
        gameDurations.length > 0
            ? Math.round(gameDurations.reduce((a, b) => a + b, 0) / gameDurations.length)
            : 0;

    return {
        gamesAnalyzed: recentGames.length,
        totalEmotionRecords,
        emotionDistribution: emotionCounts,
        initialEmotionDistribution: initialEmotionCounts,
        triggerDistribution: triggerCounts,
        gameResults: resultCounts,
        averageDurationSeconds: avgDuration,
        recentGames: recentGames.map((g) => ({
            sessionId: g.sessionId,
            startTime: g.startTime,
            initialEmotion: g.initialEmotion,
            result: g.result,
            emotionChanges: g.emotionLog.length,
        })),
    };
}

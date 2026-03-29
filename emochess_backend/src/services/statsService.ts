/**
 * 經驗值 & 等級計算服務
 */

// ─── XP 常數 ────────────────────────────────────────

/** 完成一場棋局的基礎 XP（不論輸贏） */
export const XP_BASE_COMPLETE = 30;

/** 勝利額外加成 XP */
export const XP_WIN_BONUS = 20;

/** 和局額外加成 XP */
export const XP_DRAW_BONUS = 10;

/** 等級上限 */
export const MAX_LEVEL = 50;

// ─── 等級公式 ────────────────────────────────────────

/**
 * 計算某個等級所需的單級 XP
 * 公式：level × 100
 */
export function xpRequiredForLevel(level: number): number {
    return level * 100;
}

/**
 * 計算從 Lv1 到指定等級所需的累計 XP
 * 例如 Lv3 需要 100 + 200 + 300 = 600
 */
export function cumulativeXpForLevel(level: number): number {
    // 等差數列求和：n*(n+1)/2 * 100
    return (level * (level + 1)) / 2 * 100;
}

/**
 * 根據總 XP 計算當前等級
 */
export function calculateLevel(totalXp: number): number {
    let level = 1;
    while (level < MAX_LEVEL) {
        const needed = cumulativeXpForLevel(level);
        if (totalXp < needed) break;
        level++;
    }
    return Math.min(level, MAX_LEVEL);
}

/**
 * 計算當前等級的進度資訊
 */
export function getLevelProgress(totalXp: number) {
    const level = calculateLevel(totalXp);
    const currentLevelStart = level > 1 ? cumulativeXpForLevel(level - 1) : 0;
    const nextLevelTotal = cumulativeXpForLevel(level);
    const xpInCurrentLevel = totalXp - currentLevelStart;
    const xpNeededForNextLevel = nextLevelTotal - currentLevelStart;

    return {
        level,
        totalXp,
        xpInCurrentLevel,
        xpNeededForNextLevel,
        progress: xpNeededForNextLevel > 0 ? xpInCurrentLevel / xpNeededForNextLevel : 1,
        isMaxLevel: level >= MAX_LEVEL,
    };
}

/**
 * 根據遊戲結果計算獲得的 XP
 * @param result - "white_wins" | "black_wins" | "draw" | "incomplete" | null
 * @param playerColor - 玩家使用的顏色（目前預設 "white"）
 */
export function calculateGameXp(
    result: string | null | undefined,
    playerColor: string = 'white'
): number {
    // 未完成的棋局不給 XP
    if (!result || result === 'incomplete') return 0;

    let xp = XP_BASE_COMPLETE;

    if (result === 'draw') {
        xp += XP_DRAW_BONUS;
    } else {
        // 判斷是否為玩家勝利
        const isWin =
            (playerColor === 'white' && result === 'white_wins') ||
            (playerColor === 'black' && result === 'black_wins');
        if (isWin) {
            xp += XP_WIN_BONUS;
        }
    }

    return xp;
}

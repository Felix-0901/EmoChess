import { prisma } from '../db/prisma';

type TitleDef = {
    key: string;
    nameEn: string;
    nameZh: string;
    descriptionEn: string;
    descriptionZh: string;
    rarity: 'COMMON' | 'RARE' | 'EPIC';
};

const TITLE_DEFS: TitleDef[] = [
    {
        key: 'rookie',
        nameEn: 'Rookie',
        nameZh: '新手上路',
        descriptionEn: 'Started your first steps in EmoChess.',
        descriptionZh: '踏出第一步，開始情緒棋局旅程。',
        rarity: 'COMMON',
    },
    {
        key: 'level_5',
        nameEn: 'Level 5',
        nameZh: '等級 5',
        descriptionEn: 'Reached level 5.',
        descriptionZh: '達成等級 5。',
        rarity: 'COMMON',
    },
    {
        key: 'level_10',
        nameEn: 'Level 10',
        nameZh: '等級 10',
        descriptionEn: 'Reached level 10.',
        descriptionZh: '達成等級 10。',
        rarity: 'RARE',
    },
    {
        key: 'played_10',
        nameEn: 'Regular Player',
        nameZh: '固定來一局',
        descriptionEn: 'Played 10 games.',
        descriptionZh: '累積下滿 10 局。',
        rarity: 'COMMON',
    },
    {
        key: 'played_50',
        nameEn: 'Long-Term Buddy',
        nameZh: '長期夥伴',
        descriptionEn: 'Played 50 games.',
        descriptionZh: '累積下滿 50 局。',
        rarity: 'RARE',
    },
    {
        key: 'winrate_60_30',
        nameEn: 'Consistent Winner',
        nameZh: '穩定高手',
        descriptionEn: 'Win rate ≥ 60% with at least 30 games.',
        descriptionZh: '至少 30 局且勝率 ≥ 60%。',
        rarity: 'EPIC',
    },
    {
        key: 'marathon_80',
        nameEn: 'Marathon Game',
        nameZh: '馬拉松對局',
        descriptionEn: 'Finished a game with 80+ moves.',
        descriptionZh: '完成單局 80 手以上。',
        rarity: 'RARE',
    },
    {
        key: 'bounce_back',
        nameEn: 'Bounce Back',
        nameZh: '情緒回穩',
        descriptionEn: 'Recovered from frustration during a game.',
        descriptionZh: '在同一局中從沮喪/緊張回到平穩或開心。',
        rarity: 'RARE',
    },
];

export async function ensureTitlesSeeded() {
    await Promise.all(
        TITLE_DEFS.map((t) =>
            prisma.title.upsert({
                where: { key: t.key },
                update: {
                    nameEn: t.nameEn,
                    nameZh: t.nameZh,
                    descriptionEn: t.descriptionEn,
                    descriptionZh: t.descriptionZh,
                    rarity: t.rarity,
                },
                create: {
                    key: t.key,
                    nameEn: t.nameEn,
                    nameZh: t.nameZh,
                    descriptionEn: t.descriptionEn,
                    descriptionZh: t.descriptionZh,
                    rarity: t.rarity,
                },
            })
        )
    );
}

async function hasMarathonGame(userId: string): Promise<boolean> {
    const records = await prisma.gameRecord.findMany({
        where: { userId },
        select: {
            id: true,
            _count: { select: { moves: true } },
        },
        take: 80,
        orderBy: { startTime: 'desc' },
    });
    return records.some((r) => r._count.moves >= 80);
}

async function hasBounceBackGame(userId: string): Promise<boolean> {
    const records = await prisma.gameRecord.findMany({
        where: { userId },
        select: {
            id: true,
            emotionLog: { orderBy: { timestamp: 'asc' }, select: { emotion: true } },
        },
        take: 60,
        orderBy: { startTime: 'desc' },
    });
    for (const r of records) {
        const seq = r.emotionLog.map((e) => (e.emotion || '').toLowerCase());
        if (seq.length < 2) continue;
        const firstStress = seq.findIndex((e) => e === 'frustrated' || e === 'anxious');
        if (firstStress < 0) continue;
        const after = seq.slice(firstStress + 1);
        if (after.some((e) => e === 'neutral' || e === 'happy')) {
            return true;
        }
    }
    return false;
}

export async function evaluateAndSyncTitles(userId: string) {
    await ensureTitlesSeeded();

    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { level: true, gamesPlayed: true, gamesWon: true },
    });
    if (!user) return;

    const winRate = user.gamesPlayed > 0 ? (user.gamesWon / user.gamesPlayed) * 100 : 0;

    const unlockedKeys = new Set<string>();
    unlockedKeys.add('rookie');

    if (user.level >= 5) unlockedKeys.add('level_5');
    if (user.level >= 10) unlockedKeys.add('level_10');
    if (user.gamesPlayed >= 10) unlockedKeys.add('played_10');
    if (user.gamesPlayed >= 50) unlockedKeys.add('played_50');
    if (user.gamesPlayed >= 30 && winRate >= 60) unlockedKeys.add('winrate_60_30');

    const [marathon, bounce] = await Promise.all([
        hasMarathonGame(userId),
        hasBounceBackGame(userId),
    ]);
    if (marathon) unlockedKeys.add('marathon_80');
    if (bounce) unlockedKeys.add('bounce_back');

    const titles = await prisma.title.findMany({
        where: { key: { in: Array.from(unlockedKeys) } },
        select: { id: true, key: true },
    });

    const existing = await prisma.userTitle.findMany({
        where: { userId },
        include: { title: { select: { key: true } } },
    });
    const existingKeys = new Set(existing.map((ut) => ut.title.key));

    const toCreate = titles.filter((t) => !existingKeys.has(t.key)).map((t) => t.id);

    if (toCreate.length > 0) {
        const full = await prisma.title.findMany({ where: { id: { in: toCreate } } });
        await prisma.userTitle.createMany({
            data: full.map((t) => ({ userId, titleId: t.id })),
            skipDuplicates: true,
        });
    }

    const equipped = await prisma.userTitle.findFirst({
        where: { userId, equipped: true },
        select: { id: true },
    });
    if (!equipped) {
        const first = await prisma.userTitle.findFirst({
            where: { userId },
            orderBy: { unlockedAt: 'asc' },
            select: { id: true },
        });
        if (first) {
            await prisma.userTitle.update({ where: { id: first.id }, data: { equipped: true } });
        }
    }
}

export async function listUserTitles(userId: string) {
    await evaluateAndSyncTitles(userId);
    const rows = await prisma.userTitle.findMany({
        where: { userId },
        include: { title: true },
        orderBy: [{ equipped: 'desc' }, { unlockedAt: 'asc' }],
    });

    const equipped = rows.find((r) => r.equipped) ?? null;
    return {
        equippedTitle: equipped
            ? {
                  key: equipped.title.key,
                  nameEn: equipped.title.nameEn,
                  nameZh: equipped.title.nameZh,
                  descriptionEn: equipped.title.descriptionEn,
                  descriptionZh: equipped.title.descriptionZh,
                  rarity: equipped.title.rarity,
              }
            : null,
        titles: rows.map((r) => ({
            key: r.title.key,
            nameEn: r.title.nameEn,
            nameZh: r.title.nameZh,
            descriptionEn: r.title.descriptionEn,
            descriptionZh: r.title.descriptionZh,
            rarity: r.title.rarity,
            unlockedAt: r.unlockedAt,
            equipped: r.equipped,
        })),
    };
}

export async function equipTitle(userId: string, titleKey: string) {
    await ensureTitlesSeeded();

    const title = await prisma.title.findUnique({ where: { key: titleKey } });
    if (!title) {
        const err = new Error('TITLE_NOT_FOUND');
        throw err;
    }

    const userTitle = await prisma.userTitle.findUnique({
        where: { userId_titleId: { userId, titleId: title.id } },
    });
    if (!userTitle) {
        const err = new Error('TITLE_NOT_UNLOCKED');
        throw err;
    }

    await prisma.$transaction([
        prisma.userTitle.updateMany({ where: { userId, equipped: true }, data: { equipped: false } }),
        prisma.userTitle.update({ where: { id: userTitle.id }, data: { equipped: true } }),
    ]);

    return listUserTitles(userId);
}

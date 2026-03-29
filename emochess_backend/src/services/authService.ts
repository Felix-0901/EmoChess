import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../utils/jwt';
import { getLevelProgress } from './statsService';
import { prisma } from '../db/prisma';

// ─── 驗證 Schema ────────────────────────────────────

export const registerSchema = z.object({
    email: z.string().trim().toLowerCase().email('Email 格式不正確'),
    password: z.string().min(6, '密碼至少需要 6 個字元'),
    displayName: z.string().trim().min(1, '顯示名稱不能為空').max(50),
});

export const loginSchema = z.object({
    email: z.string().trim().toLowerCase().email('Email 格式不正確'),
    password: z.string().min(1, '請輸入密碼'),
});

export const refreshSchema = z.object({
    refreshToken: z.string().min(1, '請提供 refresh token'),
});

// ─── 服務函式 ────────────────────────────────────────

/**
 * 用戶註冊
 */
export async function registerUser(data: z.infer<typeof registerSchema>) {
    // 檢查 email 是否已存在
    const existing = await prisma.user.findUnique({
        where: { email: data.email },
    });

    if (existing) {
        throw new Error('EMAIL_EXISTS');
    }

    // 雜湊密碼
    const passwordHash = await bcrypt.hash(data.password, 12);

    // 建立用戶
    const user = await prisma.user.create({
            data: {
                email: data.email,
                passwordHash,
                displayName: data.displayName,
            },
            select: {
                id: true,
                email: true,
                displayName: true,
                role: true,
                createdAt: true,
            },
        }).catch((err: any) => {
            if (err?.code === 'P2002') {
                throw new Error('EMAIL_EXISTS');
            }
            throw err;
        });

    // 產生 tokens
    const accessToken = generateAccessToken({ userId: user.id, email: user.email });
    const refreshToken = generateRefreshToken({ userId: user.id, email: user.email });

    return { user, accessToken, refreshToken };
}

/**
 * 用戶登入
 */
export async function loginUser(data: z.infer<typeof loginSchema>) {
    const user = await prisma.user.findUnique({
        where: { email: data.email },
    });

    if (!user) {
        throw new Error('INVALID_CREDENTIALS');
    }

    const isPasswordValid = await bcrypt.compare(data.password, user.passwordHash);

    if (!isPasswordValid) {
        throw new Error('INVALID_CREDENTIALS');
    }

    const accessToken = generateAccessToken({ userId: user.id, email: user.email });
    const refreshToken = generateRefreshToken({ userId: user.id, email: user.email });

    return {
        user: {
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            role: user.role,
            createdAt: user.createdAt,
        },
        accessToken,
        refreshToken,
    };
}

/**
 * 刷新 Token
 */
export async function refreshTokens(refreshToken: string) {
    const payload = verifyRefreshToken(refreshToken);

    // 確認用戶仍然存在
    const user = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { id: true, email: true },
    });

    if (!user) {
        throw new Error('USER_NOT_FOUND');
    }

    const newAccessToken = generateAccessToken({ userId: user.id, email: user.email });
    const newRefreshToken = generateRefreshToken({ userId: user.id, email: user.email });

    return { accessToken: newAccessToken, refreshToken: newRefreshToken };
}

/**
 * 取得用戶資訊
 */
export async function getUserProfile(userId: string) {
    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
            id: true,
            email: true,
            displayName: true,
            role: true,
            totalXp: true,
            level: true,
            gamesPlayed: true,
            gamesWon: true,
            createdAt: true,
            updatedAt: true,
        },
    });

    if (!user) {
        throw new Error('USER_NOT_FOUND');
    }

    const levelProgress = getLevelProgress(user.totalXp);

    return {
        ...user,
        winRate: user.gamesPlayed > 0
            ? Math.round((user.gamesWon / user.gamesPlayed) * 100)
            : 0,
        levelProgress,
    };
}

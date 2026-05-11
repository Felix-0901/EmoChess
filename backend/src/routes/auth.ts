import { Router, Request, Response } from 'express';
import {
    registerUser,
    loginUser,
    refreshTokens,
    getUserProfile,
    registerSchema,
    loginSchema,
    refreshSchema,
} from '../services/authService';
import { authMiddleware } from '../middleware/auth';

const router = Router();

/**
 * POST /api/auth/register
 * 用戶註冊
 */
router.post('/register', async (req: Request, res: Response) => {
    try {
        const data = registerSchema.parse(req.body);
        const result = await registerUser(data);

        res.status(201).json({
            message: '註冊成功',
            ...result,
        });
    } catch (err: any) {
        if (err.name === 'ZodError') {
            res.status(400).json({
                error: '請求參數驗證失敗',
                details: err.errors,
            });
            return;
        }
        if (err.message === 'EMAIL_EXISTS') {
            res.status(409).json({ error: '此 Email 已被註冊' });
            return;
        }
        if (err?.code === 'P2002') {
            res.status(409).json({ error: '此 Email 已被註冊' });
            return;
        }
        console.error('Register error:', err);
        res.status(500).json({ error: '註冊失敗' });
    }
});

/**
 * POST /api/auth/login
 * 用戶登入
 */
router.post('/login', async (req: Request, res: Response) => {
    try {
        const data = loginSchema.parse(req.body);
        const result = await loginUser(data);

        res.json({
            message: '登入成功',
            ...result,
        });
    } catch (err: any) {
        if (err.name === 'ZodError') {
            res.status(400).json({
                error: '請求參數驗證失敗',
                details: err.errors,
            });
            return;
        }
        if (err.message === 'INVALID_CREDENTIALS') {
            res.status(401).json({ error: 'Email 或密碼不正確' });
            return;
        }
        console.error('Login error:', err);
        res.status(500).json({ error: '登入失敗' });
    }
});

/**
 * POST /api/auth/refresh
 * 刷新 Token
 */
router.post('/refresh', async (req: Request, res: Response) => {
    try {
        const data = refreshSchema.parse(req.body);
        const result = await refreshTokens(data.refreshToken);

        res.json({
            message: 'Token 刷新成功',
            ...result,
        });
    } catch (err: any) {
        if (err.name === 'ZodError') {
            res.status(400).json({
                error: '請求參數驗證失敗',
                details: err.errors,
            });
            return;
        }
        res.status(401).json({ error: 'Refresh Token 無效或已過期' });
    }
});

/**
 * GET /api/auth/me
 * 取得當前用戶資訊（需認證）
 */
router.get('/me', authMiddleware, async (req: Request, res: Response) => {
    try {
        const user = await getUserProfile(req.user!.userId);
        res.json({ user });
    } catch (err: any) {
        if (err.message === 'USER_NOT_FOUND') {
            res.status(404).json({ error: '用戶不存在' });
            return;
        }
        res.status(500).json({ error: '取得用戶資訊失敗' });
    }
});

export default router;

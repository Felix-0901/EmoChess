import { Router, Request, Response } from 'express';
import { getUserProfile } from '../services/authService';
import { authMiddleware } from '../middleware/auth';

const router = Router();

/**
 * GET /api/stats/profile
 * 取得用戶完整個人數據（XP、等級、勝率等）
 */
router.get('/profile', authMiddleware, async (req: Request, res: Response) => {
    try {
        const profile = await getUserProfile(req.user!.userId);
        res.json({ profile });
    } catch (err: any) {
        if (err.message === 'USER_NOT_FOUND') {
            res.status(404).json({ error: '用戶不存在' });
            return;
        }
        res.status(500).json({ error: '取得用戶數據失敗' });
    }
});

export default router;

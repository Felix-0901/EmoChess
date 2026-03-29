import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { getEmotionSummary } from '../services/emotionService';

const router = Router();

// 所有 emotions 路由都需要認證
router.use(authMiddleware);

/**
 * GET /api/emotions/summary
 * 取得情緒統計摘要
 * Query: ?lastN=10 (最近 N 場遊戲)
 */
router.get('/summary', async (req: Request, res: Response) => {
    try {
        const lastN = Math.min(parseInt(req.query.lastN as string) || 10, 50);
        const summary = await getEmotionSummary(req.user!.userId, lastN);
        res.json({ summary });
    } catch {
        res.status(500).json({ error: '取得情緒統計失敗' });
    }
});

export default router;

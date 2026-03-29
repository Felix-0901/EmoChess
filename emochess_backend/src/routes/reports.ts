import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { getOrCreateGameReport } from '../services/reportService';

const router = Router();

router.use(authMiddleware);

router.post('/game/:gameId', async (req: Request, res: Response) => {
    try {
        const gameId = req.params.gameId as string;
        const language = (req.body as any)?.language ?? (req.query.lang as string | undefined);
        const report = await getOrCreateGameReport(req.user!.userId, gameId, language);
        res.json({ report });
    } catch (err: any) {
        if (err?.code === 'RECORD_NOT_FOUND' || err?.message === 'RECORD_NOT_FOUND') {
            res.status(404).json({ error: '找不到此遊戲記錄' });
            return;
        }
        if (err?.message === 'AI_REPORT_FAILED') {
            res.status(502).json({ error: 'AI 報告生成失敗', detail: err.detail });
            return;
        }
        if (err?.message === 'AI_REPORT_BAD_RESPONSE' || err?.message === 'AI_REPORT_NOT_JSON') {
            res.status(502).json({ error: 'AI 回應格式不正確' });
            return;
        }
        res.status(500).json({ error: '報告服務錯誤' });
    }
});

export default router;


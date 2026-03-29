import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import { equipTitle, listUserTitles } from '../services/titleService';

const router = Router();

router.use(authMiddleware);

router.get('/', async (req: Request, res: Response) => {
    try {
        const data = await listUserTitles(req.user!.userId);
        res.json(data);
    } catch {
        res.status(500).json({ error: '取得稱號失敗' });
    }
});

router.post('/equip', async (req: Request, res: Response) => {
    try {
        const key = ((req.body as any)?.key as string | undefined)?.trim();
        if (!key) {
            res.status(400).json({ error: '缺少 key' });
            return;
        }
        const data = await equipTitle(req.user!.userId, key);
        res.json(data);
    } catch (err: any) {
        if (err?.message === 'TITLE_NOT_FOUND') {
            res.status(404).json({ error: '找不到稱號' });
            return;
        }
        if (err?.message === 'TITLE_NOT_UNLOCKED') {
            res.status(403).json({ error: '尚未解鎖此稱號' });
            return;
        }
        res.status(500).json({ error: '裝備稱號失敗' });
    }
});

export default router;


import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import {
    createGameRecord,
    getGameRecords,
    getGameRecordById,
    deleteGameRecord,
    createGameSchema,
} from '../services/gameService';

const router = Router();

// 所有 games 路由都需要認證
router.use(authMiddleware);

/**
 * POST /api/games
 * 上傳完整遊戲記錄
 */
router.post('/', async (req: Request, res: Response) => {
    try {
        const data = createGameSchema.parse(req.body);
        const record = await createGameRecord(req.user!.userId, data);

        res.status(201).json({
            message: '遊戲記錄上傳成功',
            record,
        });
    } catch (err: any) {
        if (err.name === 'ZodError') {
            res.status(400).json({
                error: '請求參數驗證失敗',
                details: err.errors,
            });
            return;
        }
        // Prisma unique constraint violation (duplicate sessionId)
        if (err.code === 'P2002') {
            res.status(409).json({ error: '此遊戲記錄已存在（sessionId 重複）' });
            return;
        }
        console.error('Create game error:', err);
        res.status(500).json({ error: '上傳遊戲記錄失敗' });
    }
});

/**
 * GET /api/games
 * 取得用戶所有遊戲記錄列表
 */
router.get('/', async (req: Request, res: Response) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);

        const result = await getGameRecords(req.user!.userId, page, limit);
        res.json(result);
    } catch {
        res.status(500).json({ error: '取得遊戲記錄失敗' });
    }
});

/**
 * GET /api/games/:id
 * 取得單筆遊戲記錄詳情
 */
router.get('/:id', async (req: Request, res: Response) => {
    try {
        const record = await getGameRecordById(req.user!.userId, req.params.id as string);
        res.json({ record });
    } catch (err: any) {
        if (err.message === 'RECORD_NOT_FOUND') {
            res.status(404).json({ error: '找不到此遊戲記錄' });
            return;
        }
        res.status(500).json({ error: '取得遊戲記錄失敗' });
    }
});

/**
 * DELETE /api/games/:id
 * 刪除遊戲記錄
 */
router.delete('/:id', async (req: Request, res: Response) => {
    try {
        await deleteGameRecord(req.user!.userId, req.params.id as string);
        res.json({ message: '遊戲記錄已刪除' });
    } catch (err: any) {
        if (err.message === 'RECORD_NOT_FOUND') {
            res.status(404).json({ error: '找不到此遊戲記錄' });
            return;
        }
        res.status(500).json({ error: '刪除遊戲記錄失敗' });
    }
});

export default router;

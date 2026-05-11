import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { checkAiRateLimit, proxyChatCompletions } from '../services/aiProxyService';

const router = Router();

router.use(authMiddleware);

router.post('/chat-completions', async (req, res) => {
    const userId = req.user?.userId ?? 'unknown';
    const rate = checkAiRateLimit(userId);
    if (!rate.ok) {
        res.status(429).json({ error: 'Too many requests', retryAfterMs: rate.retryAfterMs });
        return;
    }

    const result = await proxyChatCompletions(req.body);
    res.status(result.status).json(result.data);
});

export default router;


import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import { prisma } from './db/prisma';
import authRoutes from './routes/auth';
import gameRoutes from './routes/games';
import emotionRoutes from './routes/emotions';
import statsRoutes from './routes/stats';

const app = express();

// ─── Middleware ──────────────────────────────────────

app.use(helmet());
const corsOrigins = env.CORS_ORIGIN
    ? env.CORS_ORIGIN.split(',').map((o) => o.trim()).filter(Boolean)
    : undefined;
app.use(
    cors({
        origin: corsOrigins ?? true,
        credentials: true,
    })
);
app.use(express.json({ limit: '10mb' })); // 遊戲記錄可能較大

// ─── Routes ─────────────────────────────────────────

app.get('/api/health', async (_req, res) => {
    try {
        await prisma.$queryRaw`SELECT 1`;
        res.json({
            status: 'ok',
            service: 'EmoChess Backend API',
            db: 'ok',
            timestamp: new Date().toISOString(),
        });
    } catch {
        res.status(503).json({
            status: 'degraded',
            service: 'EmoChess Backend API',
            db: 'down',
            timestamp: new Date().toISOString(),
        });
    }
});

app.use('/api/auth', authRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/emotions', emotionRoutes);
app.use('/api/stats', statsRoutes);

// ─── Error Handler ──────────────────────────────────

app.use(errorHandler);

// ─── Start Server ───────────────────────────────────

app.listen(env.PORT, () => {
    console.log(`
  ────────────────────────
  EmoChess Backend API
  Server:  http://localhost:${env.PORT}
  Health:  http://localhost:${env.PORT}/api/health
  Auth:    http://localhost:${env.PORT}/api/auth
  Games:   http://localhost:${env.PORT}/api/games
  Emotions: http://localhost:${env.PORT}/api/emotions
  Stats:    http://localhost:${env.PORT}/api/stats
  ────────────────────────
  Environment: ${env.NODE_ENV}
  `);
});

export default app;

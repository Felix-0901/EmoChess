import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import { prisma } from './db/prisma';
import authRoutes from './routes/auth';
import gameRoutes from './routes/games';
import emotionRoutes from './routes/emotions';
import statsRoutes from './routes/stats';
import aiRoutes from './routes/ai';
import reportRoutes from './routes/reports';
import titleRoutes from './routes/titles';

const app = express();
app.disable('x-powered-by');
if (env.NODE_ENV === 'production') {
    app.set('trust proxy', 1);
}

// ─── Middleware ──────────────────────────────────────

app.use(
    helmet({
        contentSecurityPolicy: false,
    })
);
const corsOrigins = env.CORS_ORIGIN?.split(',').map((o) => o.trim()).filter(Boolean);
if (corsOrigins && corsOrigins.length > 0) {
    app.use(
        cors({
            origin: corsOrigins,
            credentials: true,
        })
    );
}
app.use(
    rateLimit({
        windowMs: env.GLOBAL_RATE_LIMIT_WINDOW_MS,
        limit: env.GLOBAL_RATE_LIMIT_MAX,
        standardHeaders: 'draft-8',
        legacyHeaders: false,
        skip: (req) => req.path === '/health' || req.path === '/api/health',
        message: {
            error: 'Too many requests',
        },
    })
);
app.use(express.json({ limit: '10mb' })); // 遊戲記錄可能較大
app.use(compression());

// ─── Routes ─────────────────────────────────────────

const healthHandler: express.RequestHandler = async (_req, res) => {
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
};

app.get('/', (_req, res) => {
    res.json({
        service: 'EmoChess Backend API',
        status: 'ok',
        health: '/api/health',
    });
});

app.get('/health', healthHandler);
app.get('/api/health', healthHandler);

const openapi = {
    openapi: '3.0.3',
    info: {
        title: 'EmoChess Backend API',
        version: '1.0.0',
    },
    servers: [{ url: '/' }],
    components: {
        securitySchemes: {
            bearerAuth: {
                type: 'http',
                scheme: 'bearer',
                bearerFormat: 'JWT',
            },
        },
    },
    paths: {
        '/health': {
            get: {
                summary: 'Health check',
                responses: { '200': { description: 'OK' }, '503': { description: 'Degraded' } },
            },
        },
        '/api/health': {
            get: {
                summary: 'Health check',
                responses: { '200': { description: 'OK' }, '503': { description: 'Degraded' } },
            },
        },
        '/api/auth/register': {
            post: {
                summary: 'Register',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { type: 'object' } } },
                },
                responses: {
                    '201': { description: 'Created' },
                    '400': { description: 'Bad Request' },
                    '409': { description: 'Conflict' },
                },
            },
        },
        '/api/auth/login': {
            post: {
                summary: 'Login',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { type: 'object' } } },
                },
                responses: { '200': { description: 'OK' }, '400': { description: 'Bad Request' }, '401': { description: 'Unauthorized' } },
            },
        },
        '/api/auth/refresh': {
            post: {
                summary: 'Refresh token',
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { type: 'object' } } },
                },
                responses: { '200': { description: 'OK' }, '400': { description: 'Bad Request' }, '401': { description: 'Unauthorized' } },
            },
        },
        '/api/auth/me': {
            get: {
                summary: 'Get current user',
                security: [{ bearerAuth: [] }],
                responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' }, '404': { description: 'Not Found' } },
            },
        },
        '/api/games': {
            get: {
                summary: 'List game records',
                security: [{ bearerAuth: [] }],
                parameters: [
                    { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1 } },
                    { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 100 } },
                ],
                responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' } },
            },
            post: {
                summary: 'Create game record',
                security: [{ bearerAuth: [] }],
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { type: 'object' } } },
                },
                responses: { '201': { description: 'Created' }, '400': { description: 'Bad Request' }, '401': { description: 'Unauthorized' }, '409': { description: 'Conflict' } },
            },
        },
        '/api/games/{id}': {
            get: {
                summary: 'Get game record by id',
                security: [{ bearerAuth: [] }],
                parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
                responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' }, '404': { description: 'Not Found' } },
            },
            delete: {
                summary: 'Delete game record',
                security: [{ bearerAuth: [] }],
                parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
                responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' }, '404': { description: 'Not Found' } },
            },
        },
        '/api/emotions/summary': {
            get: {
                summary: 'Get emotion summary',
                security: [{ bearerAuth: [] }],
                parameters: [{ name: 'lastN', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 50 } }],
                responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' } },
            },
        },
        '/api/stats/profile': {
            get: {
                summary: 'Get user profile stats',
                security: [{ bearerAuth: [] }],
                responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' }, '404': { description: 'Not Found' } },
            },
        },
        '/api/ai/chat-completions': {
            post: {
                summary: 'AI chat completions (proxy)',
                security: [{ bearerAuth: [] }],
                requestBody: {
                    required: true,
                    content: { 'application/json': { schema: { type: 'object' } } },
                },
                responses: { '200': { description: 'OK' }, '400': { description: 'Bad Request' }, '401': { description: 'Unauthorized' }, '429': { description: 'Too Many Requests' }, '502': { description: 'Bad Gateway' } },
            },
        },
    },
};

if (env.NODE_ENV !== 'production') {
    app.get('/openapi.json', (_req, res) => {
        res.json(openapi);
    });

    app.use('/docs', swaggerUi.serve, swaggerUi.setup(openapi));
}

app.use('/api/auth', authRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/emotions', emotionRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/titles', titleRoutes);

// ─── Error Handler ──────────────────────────────────

app.use(errorHandler);

// ─── Start Server ───────────────────────────────────

const server = app.listen(env.PORT, () => {
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

const shutdown = async (signal: string) => {
    try {
        console.log(`[shutdown] received ${signal}`);
        await new Promise<void>((resolve) => server.close(() => resolve()));
        await prisma.$disconnect();
        process.exit(0);
    } catch (err) {
        console.error('[shutdown] error', err);
        process.exit(1);
    }
};

process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('unhandledRejection', (reason) => {
    console.error('[unhandledRejection]', reason);
});
process.on('uncaughtException', (err) => {
    console.error('[uncaughtException]', err);
    void shutdown('uncaughtException');
});

export default app;

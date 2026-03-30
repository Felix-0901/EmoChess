import dotenv from 'dotenv';
import { z } from 'zod';
dotenv.config();

const envSchema = z
    .object({
        NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
        PORT: z.coerce.number().int().positive().default(3000),
        DATABASE_URL: z.string().min(1, 'DATABASE_URL 必填'),
        JWT_SECRET: z.string().min(1, 'JWT_SECRET 必填'),
        JWT_REFRESH_SECRET: z.string().min(1, 'JWT_REFRESH_SECRET 必填'),
        JWT_EXPIRES_IN: z.string().default('15m'),
        JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
        CORS_ORIGIN: z.string().optional(),
        AI_BASE_URL: z.string().optional(),
        OPENAI_BASE_URL: z.string().optional(),
        AI_API_KEY: z.string().optional(),
        OPENAI_API_KEY: z.string().optional(),
        AI_MODEL: z.string().optional(),
        OPENAI_MODEL: z.string().optional(),
        AI_TIMEOUT_MS: z.coerce.number().int().positive().default(20000),
        AI_RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
        AI_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(30),
    })
    .superRefine((val, ctx) => {
        if (val.NODE_ENV === 'production') {
            if (!val.CORS_ORIGIN || val.CORS_ORIGIN.trim().length === 0) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    message: 'CORS_ORIGIN 在 production 必填',
                    path: ['CORS_ORIGIN'],
                });
            } else {
                const origins = val.CORS_ORIGIN.split(',')
                    .map((o) => o.trim())
                    .filter(Boolean);
                if (origins.includes('*')) {
                    ctx.addIssue({
                        code: z.ZodIssueCode.custom,
                        message: 'CORS_ORIGIN 不可包含 "*"（搭配 credentials 會造成任意來源存取）',
                        path: ['CORS_ORIGIN'],
                    });
                }
            }
            if (val.JWT_SECRET.trim().length < 32) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    message: 'JWT_SECRET 長度至少 32 字元',
                    path: ['JWT_SECRET'],
                });
            }
            if (val.JWT_REFRESH_SECRET.trim().length < 32) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    message: 'JWT_REFRESH_SECRET 長度至少 32 字元',
                    path: ['JWT_REFRESH_SECRET'],
                });
            }
            const key = (val.AI_API_KEY ?? val.OPENAI_API_KEY ?? '').trim();
            if (key.length === 0) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    message: 'AI_API_KEY 在 production 必填',
                    path: ['AI_API_KEY'],
                });
            }
        }
    });

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
    const issues = parsed.error.issues
        .map((i) => `${i.path.join('.') || 'env'}: ${i.message}`)
        .join('\n');
    throw new Error(`環境變數設定錯誤:\n${issues}`);
}

const raw = parsed.data;
export const env = {
    ...raw,
    AI_BASE_URL: (raw.AI_BASE_URL ?? raw.OPENAI_BASE_URL ?? 'https://api.openai.com').trim(),
    AI_API_KEY: ((raw.AI_API_KEY ?? raw.OPENAI_API_KEY ?? '').trim() || undefined) as string | undefined,
    AI_MODEL: (raw.AI_MODEL ?? raw.OPENAI_MODEL ?? 'gpt-4o-mini').trim(),
};

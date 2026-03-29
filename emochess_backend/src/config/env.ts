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
    })
    .superRefine((val, ctx) => {
        if (val.NODE_ENV === 'production') {
            if (!val.CORS_ORIGIN || val.CORS_ORIGIN.trim().length === 0) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    message: 'CORS_ORIGIN 在 production 必填',
                    path: ['CORS_ORIGIN'],
                });
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
        }
    });

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
    const issues = parsed.error.issues
        .map((i) => `${i.path.join('.') || 'env'}: ${i.message}`)
        .join('\n');
    throw new Error(`環境變數設定錯誤:\n${issues}`);
}

export const env = parsed.data;

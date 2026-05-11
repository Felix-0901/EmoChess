import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';

/**
 * 統一錯誤處理 Middleware
 */
export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
    console.error(err);

    if (err instanceof ZodError) {
        res.status(400).json({
            error: '請求參數驗證失敗',
            details: err.issues,
        });
        return;
    }

    res.status(500).json({
        error: '伺服器內部錯誤',
        ...(process.env.NODE_ENV === 'development' && { message: err.message }),
    });
}

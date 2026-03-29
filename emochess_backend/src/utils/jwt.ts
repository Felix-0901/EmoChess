import jwt from 'jsonwebtoken';
import { env } from '../config/env';

interface TokenPayload {
    userId: string;
    email: string;
}

/**
 * 產生 access token (短期)
 */
export function generateAccessToken(payload: TokenPayload): string {
    return jwt.sign(
        payload,
        env.JWT_SECRET,
        { expiresIn: env.JWT_EXPIRES_IN } as jwt.SignOptions
    );
}

/**
 * 產生 refresh token (長期)
 */
export function generateRefreshToken(payload: TokenPayload): string {
    return jwt.sign(
        payload,
        env.JWT_REFRESH_SECRET,
        { expiresIn: env.JWT_REFRESH_EXPIRES_IN } as jwt.SignOptions
    );
}

/**
 * 驗證 access token
 */
export function verifyAccessToken(token: string): TokenPayload {
    return jwt.verify(token, env.JWT_SECRET) as TokenPayload;
}

/**
 * 驗證 refresh token
 */
export function verifyRefreshToken(token: string): TokenPayload {
    return jwt.verify(token, env.JWT_REFRESH_SECRET) as TokenPayload;
}

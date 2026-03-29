# EmoChess Backend API

Node.js + Express + TypeScript 的 API 服務，使用 PostgreSQL 與 Prisma 儲存用戶、對局與情緒資料，並以 JWT（access/refresh）進行認證。

## 技術棧

- Node.js, Express, TypeScript
- PostgreSQL, Prisma
- JWT access token + refresh token
- Docker, Docker Compose

## 環境變數

本專案會在啟動時驗證環境變數，設定不完整會直接拒絕啟動（避免以不安全的預設值運行）。

必要變數（development 與 production 都需要）：

- DATABASE_URL
- JWT_SECRET
- JWT_REFRESH_SECRET

production 額外要求：

- CORS_ORIGIN（允許的來源網域，可用逗號分隔）
- JWT_SECRET 與 JWT_REFRESH_SECRET 長度至少 32 字元

可選：

- PORT（預設 3000）
- JWT_EXPIRES_IN（預設 15m）
- JWT_REFRESH_EXPIRES_IN（預設 7d）

## 本地開發（Docker）

1. 建立環境檔

```bash
cp .env.example .env
```

2. 編輯 `.env`，至少填好：

- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- DATABASE_URL
- JWT_SECRET
- JWT_REFRESH_SECRET

3. 啟動（含 DB 與 API）

```bash
docker compose up -d
```

4. 健康檢查

```bash
curl http://localhost:3000/api/health
```

## API 端點

| Method | Path | 說明 | 認證 |
|--------|------|------|------|
| GET | `/api/health` | 健康檢查（含 DB 狀態） | 否 |
| POST | `/api/auth/register` | 用戶註冊 | 否 |
| POST | `/api/auth/login` | 用戶登入 | 否 |
| POST | `/api/auth/refresh` | 刷新 Token | 否 |
| GET | `/api/auth/me` | 取得用戶資訊 | 是 |
| POST | `/api/games` | 上傳遊戲記錄 | 是 |
| GET | `/api/games` | 遊戲記錄列表 | 是 |
| GET | `/api/games/:id` | 遊戲記錄詳情 | 是 |
| DELETE | `/api/games/:id` | 刪除遊戲記錄 | 是 |
| GET | `/api/emotions/summary` | 情緒統計摘要 | 是 |
| GET | `/api/stats/profile` | 用戶完整個人數據 | 是 |

## Coolify 部署

使用 `docker-compose.coolify.yml` 部署，在 Coolify 設定：

- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- JWT_SECRET
- JWT_REFRESH_SECRET
- CORS_ORIGIN
- JWT_EXPIRES_IN（可選）
- JWT_REFRESH_EXPIRES_IN（可選）

## 常用指令

```bash
npm run dev
npm run build
npm run db:generate
npm run db:migrate
npm run db:studio
npm run docker:up
npm run docker:down
npm run docker:logs
```

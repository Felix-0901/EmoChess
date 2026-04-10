# EmoChess 後端（Backend API）

## 模組簡介

Node.js + Express + TypeScript 的 API 服務，使用 PostgreSQL 與 Prisma 儲存用戶、對局與情緒資料，並以 JWT（access/refresh）進行認證。AI 功能採後端代呼叫模式：App 以 JWT 呼叫後端，AI 金鑰只放在後端環境變數。

## 使用技術

- Node.js（Dockerfile 使用 `node:20-alpine`）
- Express 5 + TypeScript
- PostgreSQL, Prisma
- JWT access token + refresh token
- Docker, Docker Compose
- Zod（啟動時驗證環境變數）

## 資料夾結構

```text
emochess_backend/
  prisma/
    schema.prisma
    migrations/
  src/
    config/        # 環境變數載入與驗證
    db/            # Prisma Client
    middleware/    # auth / error handler
    routes/        # 各 API 路由
    services/      # 商業邏輯（AI 代理、棋局、情緒、報告、稱號...）
    utils/         # JWT 等共用工具
    index.ts       # Server 入口
  docker-compose.yml
  docker-compose.coolify.yml
  Dockerfile
  .env.example
```

## 本地開發流程

### 方式 A：Docker Compose（推薦）

1. 建立環境檔

```bash
cp .env.example .env
```

2. 編輯 `.env`（至少填好）：

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`（Docker Compose 情境請使用 `@postgres:5432`，範例已寫在 `.env.example`）
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`

3. 啟動（含 DB 與 API）

```bash
docker compose up -d
```

4. 健康檢查

```bash
curl http://localhost:3000/api/health
```

### 方式 B：不使用 Docker（API 本機直跑）

1. 啟動 PostgreSQL（方式不限）
2. 建立 `.env`，並將 `DATABASE_URL` 改成連線到 `localhost`
3. 安裝依賴與啟動

```bash
npm ci
npm run db:generate
npm run db:migrate
npm run dev
```

## 環境變數

本專案會在啟動時驗證環境變數；設定不完整或不安全會直接拒絕啟動（避免以錯誤設定運行）。環境變數鍵名與註解以 `.env.example` 為準。

必要變數（development 與 production 都需要）：

- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`

production 額外驗證：

- `JWT_SECRET` 與 `JWT_REFRESH_SECRET` 長度至少 32 字元
- 需提供 AI 金鑰（`AI_API_KEY` 或 `OPENAI_API_KEY` 其一）
- 若有設定 `CORS_ORIGIN`：
  - 可用逗號分隔多個來源
  - 不可包含 `*`

可選：

- `PORT`（預設 `3000`）
- `NODE_ENV`（預設 `development`）
- `CORS_ORIGIN`（只有需要讓「瀏覽器」跨網域呼叫 API 時才需要）
- `JWT_EXPIRES_IN`（預設 `15m`）
- `JWT_REFRESH_EXPIRES_IN`（預設 `7d`）
- `AI_BASE_URL`（預設 `https://api.openai.com`，也可用 `OPENAI_BASE_URL`）
- `AI_MODEL`（預設 `gpt-4o-mini`，也可用 `OPENAI_MODEL`）
- `AI_TIMEOUT_MS`（預設 `20000`）
- `AI_RATE_LIMIT_WINDOW_MS`（預設 `60000`）
- `AI_RATE_LIMIT_MAX`（預設 `30`）

## 建置 / 啟動方式

```bash
npm run dev
npm run build
npm run start
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

## 部署細節

### Coolify（Docker Compose）

使用 `docker-compose.coolify.yml` 部署，需提供的環境變數以檔案內 `${...}` 為準（也可對照 `.env.example`）：

- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- JWT_SECRET
- JWT_REFRESH_SECRET
- CORS_ORIGIN（只有需要讓瀏覽器跨網域呼叫 API 時才需要）
- JWT_EXPIRES_IN（可選）
- JWT_REFRESH_EXPIRES_IN（可選）
- AI_API_KEY（或 OPENAI_API_KEY）
- AI_BASE_URL（可選）
- AI_MODEL（可選）

容器啟動時會先執行 `prisma migrate deploy` 再啟動 API；健康檢查端點為 `/api/health`（含 DB 狀態）。

### 健康檢查 / 文件

- 健康檢查：`GET /api/health`（或 `GET /health`）
- 開發文件（非 production 才會啟用）：
  - `GET /openapi.json`
  - `GET /docs`

## 常見問題

### `DATABASE_URL` 連不上資料庫

- 用 Docker Compose（`docker compose up`）時，`DATABASE_URL` host 請用 `postgres`
- API 本機直跑（`npm run dev`）時，`DATABASE_URL` host 請用 `localhost` 或 `127.0.0.1`

### production 啟動失敗：環境變數驗證錯誤

- 檢查 `JWT_SECRET` / `JWT_REFRESH_SECRET` 是否至少 32 字元
- 檢查是否已提供 `AI_API_KEY` 或 `OPENAI_API_KEY`

### Flutter App 呼叫 API 需要設定 `CORS_ORIGIN` 嗎？

不需要。Flutter App 非瀏覽器情境，不受瀏覽器 CORS 限制；只有要讓瀏覽器網頁端跨網域呼叫 API 時才需要設定 `CORS_ORIGIN`。

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

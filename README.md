# EmoChess

## 專案名稱

EmoChess

## 專案簡介

EmoChess 是一個以西洋棋為媒介的情緒陪伴與學習專案，包含：

- Flutter App：遊戲介面、情緒記錄、對局分析與互動式陪伴對話
- Backend API：帳號認證、對局與情緒資料儲存（PostgreSQL + Prisma）

本專案採用 monorepo 結構，前後端分離。後端可用 Docker Compose 本地啟動，也可用 Coolify 以 Docker Compose 部署。

## 功能列表

- 帳號註冊 / 登入 / Token 刷新（JWT access/refresh）
- 棋局上傳、列表、詳情、刪除（雲端為準，跨裝置一致）
- 情緒打卡與情緒摘要統計
- AI 陪伴對話與 AI 報告（由後端代呼叫，App 不保存任何 AI 金鑰）
- 稱號 / 個人統計（由後端提供資料）

## 技術架構

- 前端：Flutter App（`app`）
  - 以 `--dart-define=API_BASE_URL=...` 決定後端位址（不提供 App 內調整後端位址）
  - 使用 `flutter_secure_storage` 儲存登入 Token
- 後端：Node.js + Express + TypeScript（`backend`）
  - 以 Prisma 存取 PostgreSQL
  - 以 JWT middleware 保護需要登入的 API
  - AI 相關功能由後端接收 App 的 JWT 後代呼叫第三方 AI（AI 金鑰只放在後端環境變數）
- 資料庫：PostgreSQL（Docker Compose 本地 / Coolify 部署）

## 專案結構

- `app/`：Flutter 應用程式
- `backend/`：Node.js + Express + Prisma API
- `docker-compose.yml`：從根目錄啟動後端＋資料庫（搭配 `--env-file backend/.env`）

## 本地測試教學

本段以「後端＋資料庫用 Docker Compose」搭配「Flutter App 直跑」為主。

### 1) 啟動後端與資料庫（Docker Compose）

1. 建立後端環境檔

```bash
cp backend/.env.example backend/.env
```

2. 編輯 `backend/.env`，至少設定（請勿提交 `.env`）：

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`（用 Docker Compose 啟動時，host 請用 `postgres`，可參考 `.env.example`）
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`

3. 從專案根目錄啟動（會啟動 `postgres:5432` 與 `api:3000`）

```bash
docker compose --env-file backend/.env up -d
```

4. 健康檢查

```bash
curl http://localhost:3000/api/health
```

### 2) 啟動 Flutter App（本機）

```bash
cd app
flutter pub get
```

啟動時使用 `--dart-define` 指定後端 API Base URL（建議包含 `/api`；若只給網域，App 會自動補成 `/api`）：

- Android Emulator：

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

- iOS Simulator / macOS / Windows / Linux：

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

AI 採「後端代呼叫」模式：AI 金鑰放在後端環境變數，App 不保存任何 AI 金鑰。

- App 以登入後的 JWT 呼叫後端 AI API（例如 `/api/ai/...`）
- 後端以環境變數提供 AI 金鑰（詳見後端 README）

## 環境變數

環境變數的範本與鍵名以後端的 `backend/.env.example` 為準。

- 後端（本地 Docker Compose）
  - 從根目錄執行 `docker compose --env-file backend/.env up -d`
  - `DATABASE_URL` 請指向 `postgres` service（可直接沿用 `.env.example` 的 compose 範例）
- 後端（production / Coolify）
  - 需要正確設定 `DATABASE_URL`、JWT secrets、以及（若有瀏覽器網頁端）`CORS_ORIGIN`
  - AI 相關金鑰（例如 `AI_API_KEY` 或 `OPENAI_API_KEY`）只放後端環境變數
- 前端（Flutter App）
  - `API_BASE_URL` 透過 `--dart-define=API_BASE_URL=...` 注入
  - 未指定 `API_BASE_URL` 時會使用預設正式環境位址（見 App README）

## Coolify 部署教學

後端部署建議使用 `backend/docker-compose.coolify.yml`。

- 部署時需提供的關鍵環境變數：
  - `POSTGRES_DB`、`POSTGRES_USER`、`POSTGRES_PASSWORD`
  - `JWT_SECRET`、`JWT_REFRESH_SECRET`
  - `GLOBAL_RATE_LIMIT_WINDOW_MS`、`GLOBAL_RATE_LIMIT_MAX`（可選；預設每 IP 每 15 分鐘 300 次）
  - `CORS_ORIGIN`（只有需要讓瀏覽器跨網域呼叫 API 時才需要；不可包含 `*`）
  - `AI_API_KEY` 或 `OPENAI_API_KEY`（若要啟用 AI 功能）
- 服務啟動後用健康檢查確認：
  - `GET /api/health`

## 前端 / 後端詳細文件連結

- 前端（Flutter App）：[app/README.md](./app/README.md)
- 後端（API）：[backend/README.md](./backend/README.md)

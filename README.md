# EmoChess

EmoChess 是一個以西洋棋為媒介的情緒陪伴與學習專案，包含：

- Flutter App：遊戲介面、情緒記錄、對局分析與互動式陪伴對話
- Backend API：帳號認證、對局與情緒資料儲存（PostgreSQL + Prisma）

本專案採用 monorepo 結構，前後端分離，部署目標為 Coolify，資料庫使用 PostgreSQL。本地開發與測試以 Docker Compose 啟動後端與資料庫。

## 專案結構

- emochess_app：Flutter 應用程式
- emochess_backend：Node.js + Express + Prisma API

## 本地啟動（Docker + Flutter）

### 1) 啟動後端與資料庫（Docker）

1. 建立後端環境檔

```bash
cp emochess_backend/.env.example emochess_backend/.env
```

2. 編輯 `emochess_backend/.env`，至少設定：

- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- DATABASE_URL
- JWT_SECRET
- JWT_REFRESH_SECRET

3. 從專案根目錄啟動

```bash
docker compose up -d
```

4. 健康檢查

```bash
curl http://localhost:3000/api/health
```

### 2) 啟動 Flutter App

```bash
cd emochess_app
flutter pub get
```

啟動時使用 `--dart-define` 指定後端 API Base URL（必填，需包含 `/api`）：

- Android Emulator：

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

- iOS Simulator / macOS / Windows / Linux：

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

AI 功能可選，若要啟用可設定：

- AI_BASE_URL（預設 `https://free.v36.cm`）
- AI_API_KEY（未設定時 AI 會自動停用並回退至內建互動）

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api \
  --dart-define=AI_BASE_URL=https://free.v36.cm \
  --dart-define=AI_API_KEY=your-key
```

## 部署（Coolify）

後端部署建議使用 [docker-compose.coolify.yml](file:///Users/felix/Documents/EmoChess/emochess_backend/docker-compose.coolify.yml)。

在 Coolify 設定環境變數：

- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- JWT_SECRET
- JWT_REFRESH_SECRET
- CORS_ORIGIN
- JWT_EXPIRES_IN（可選，預設 15m）
- JWT_REFRESH_EXPIRES_IN（可選，預設 7d）

## 開發注意事項

- 請勿將 `.env`、私鑰、Token 等敏感資訊提交到版本控制
- production 環境下後端會強制要求 `CORS_ORIGIN` 與足夠長度的 JWT secret


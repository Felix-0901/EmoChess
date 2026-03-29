# EmoChess 專案穩定化與整理計畫

目標：把目前的前後端做「可部署、可設定、可維護」的最小整理，先把不穩定與安全風險移除，再逐步優化功能與架構。文件（根目錄 / 前端 / 後端 README）全部不使用 Emoji。

參考專案：Literary Life 的 monorepo 分層、Docker 本地啟動流程、Coolify 部署思路（但本專案後端為 Node.js + Express + Prisma，非 FastAPI）。

---

## 里程碑 0：Git 重新初始化（去除歷史與殘留）

1. 檢查並移除所有 `.git` 目錄（根目錄與子目錄），避免殘留歷史與 remote 設定。
2. 重新初始化 Git：
   - `git init`、設定預設分支（例如 `main`）。
   - 建立/整理根目錄 `.gitignore`（涵蓋 Flutter、Node、Docker、IDE、產物）。
3. 確認 repo 內無任何金鑰或密碼被寫死（特別是 AI Key、JWT secret、DB 密碼）。

驗收：
- 專案內不存在 `.git`（重新初始化前），重新初始化後僅保留新的 `.git`。
- `git status` 不會顯示任何敏感資訊檔案（例如 `.env`、金鑰檔）。

---

## 里程碑 1：後端（Node/Express/Prisma）穩定化

### 1.1 環境變數與設定

1. 用 Zod 驗證環境變數（既有相依：`zod`），取代目前的 fallback secret 行為：
   - `DATABASE_URL`、`JWT_SECRET`、`JWT_REFRESH_SECRET` 在 production 必填。
   - 支援 `CORS_ORIGIN`（可選），避免預設全開。
2. 整理 `.env.example`：
   - 不放任何可用的預設密碼/金鑰（只留示例字串）。
3. 調整 `docker-compose.yml`（本地開發）：
   - 不再把 JWT secret 與 DB 密碼寫死在檔案內。
   - 改用 `.env` / `env_file` 或 `${VAR}` substitution。

### 1.2 錯誤處理與回應一致性

1. 修正 `errorHandler`：
   - 以 `err instanceof ZodError` 處理 Zod 驗證錯誤，回傳 `.issues`。
   - 避免 `JSON.parse(err.message)` 造成二次崩潰。
2. 統一 API 錯誤格式（至少包含 `error`、可選 `details`）。
3. 增強健康檢查：
   - `/api/health` 增加 DB 連線基本檢查（例如簡單 query / Prisma ping）。

### 1.3 Docker 與部署一致性

1. 讓 `docker-compose.coolify.yml` 與本地 compose 在變數命名與啟動策略一致：
   - `DATABASE_URL` 組裝規則一致。
   - migration 策略一致（目前 Dockerfile 在啟動時 `migrate deploy`，保留）。
2. 將 package scripts 更新為 `docker compose ...`（避免舊版 `docker-compose` 指令差異）。

驗收：
- `docker compose up -d` 可在本地拉起 Postgres + API，並可正常打 `/api/health`。
- 未設定 production 必要變數時，API 會明確拒絕啟動（而不是用 fallback secret）。

---

## 里程碑 2：前端（Flutter）穩定化

### 2.1 統一環境設定（Base URL / AI 設定）

1. 建立 `AppConfig`（集中管理）：
   - `API_BASE_URL`（你的後端）以 `--dart-define` 注入。
   - `AI_BASE_URL`、`AI_API_KEY` 以 `--dart-define` 注入。
2. 移除硬編碼：
   - `AuthService` 不再寫死 `http://localhost:3000/api`。
   - `AiCompanionService` 移除「未配置就 fallback 到硬編碼 key」的危險行為。
3. AI 可選啟用：
   - 若未提供 `AI_API_KEY`，App 仍能正常玩棋與使用非 AI 的分析（或顯示「AI 功能未啟用」提示），避免卡死。

### 2.2 網路韌性與錯誤處理

1. 增加 timeout，避免請求無限等待。
2. AI 429/backoff 增加最大嘗試次數與上限，避免 `while(true)` 無限迴圈。
3. Auth JSON decode 做防護（伺服器回非 JSON 時能顯示可理解錯誤）。
4. Refresh 流程限制重試次數，避免遞迴與併發風暴。

### 2.3 Token 儲存安全

1. 將 access/refresh token 從 `SharedPreferences` 改為 `flutter_secure_storage`。
2. 抽象 `TokenStorage` 介面，讓測試與替換更容易。

驗收：
- Android Emulator、真機、Web（若使用）都能透過 `--dart-define=API_BASE_URL=...` 正確連線。
- 未設定 AI key 時不會 crash、不會卡住遊戲流程。

---

## 里程碑 3：Monorepo 文件與開發體驗整理

### 3.1 README（不含 Emoji）

1. 根目錄 README：
   - 專案介紹、目錄結構、需求（Flutter / Docker / Node）、本地啟動（Docker 起後端 + DB，Flutter 連線）。
   - 環境變數總表與範例（不含實際密碼/金鑰）。
   - Coolify 部署流程（以 backend compose 模板為主，DB 使用 PostgreSQL）。
2. 前端 README：
   - Flutter 啟動方式（Android emulator / iOS simulator / 實機）、`--dart-define` 參數清單。
   - 常見問題（10.0.2.2、CORS、API 連線測試）。
3. 後端 README：
   - Docker 本地啟動、Prisma migrate、資料庫連線、健康檢查。
   - Coolify 環境變數對照表。

### 3.2 根目錄 Docker（可選但建議）

1. 新增根目錄 `docker-compose.yml`（或 `compose.yml`）：
   - 一鍵啟動 `emochess_backend` 的 API + PostgreSQL（方便本地測試與 CI）。
   - 以 env 檔管理 secrets，並提供 `.env.example`。

驗收：
- 新同事照 README 可在本地完成「起 DB + API」與「App 連線登入」。
- 用 Coolify 按 README 設定環境變數即可部署成功。

---

## 執行順序（確認後會照此做）

1. Git 重置與重新初始化（不改功能，先確保乾淨與安全）
2. 後端：env 驗證、錯誤處理、compose 安全化、healthcheck 強化
3. 前端：環境設定集中化、移除硬編碼與外洩 key、增加 timeout/重試上限、secure storage
4. 文件：根目錄/前端/後端 README 全面更新（無 Emoji），補齊本地 Docker 與 Coolify 指引


# EmoChess App

Flutter 應用程式，提供西洋棋對弈、情緒記錄、對局分析與互動式陪伴對話。後端 API 與資料庫由 `emochess_backend` 提供。

## 技術要點

- Flutter + Dart
- Provider 狀態管理
- GoRouter 導航
- 本地資料：Hive（一般資料）、flutter_secure_storage（Token）
- 網路：http

## 本地啟動

1. 安裝依賴

```bash
flutter pub get
```

2. 指定後端 API Base URL（必須包含 `/api`）

- Android Emulator：

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

- iOS Simulator / macOS / Windows / Linux：

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

3. 可選：啟用 AI

若未提供 `AI_API_KEY`，App 仍可正常運行，AI 對話會自動回退到內建互動邏輯。

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api \
  --dart-define=AI_BASE_URL=https://free.v36.cm \
  --dart-define=AI_API_KEY=your-key
```

## 設定參數

- API_BASE_URL：後端 API base URL（例如 `http://localhost:3000/api`）
- AI_BASE_URL：AI 服務 base URL（預設 `https://free.v36.cm`）
- AI_API_KEY：AI 服務金鑰（未設定即停用 AI）

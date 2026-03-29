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

 - iOS / Android 實體手機（手機與電腦同一個 Wi‑Fi）：

```bash
flutter run --dart-define=API_BASE_URL=http://<你的電腦區網IP>:3000/api
```

也可以在 App 內「設定」頁（Debug 模式才會顯示）直接修改「後端伺服器」，輸入 `http://<你的電腦區網IP>:3000`（未包含 `/api` 會自動補上）。

## 設定參數

- API_BASE_URL：後端 API base URL（例如 `http://localhost:3000/api`）
 
AI 金鑰採正式產品作法：放在後端環境變數（例如 Coolify / Secrets），App 端不保存任何 AI 金鑰。

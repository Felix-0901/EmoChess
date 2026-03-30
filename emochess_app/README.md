# EmoChess App

Flutter 應用程式，提供西洋棋對弈、情緒記錄、對局分析與互動式陪伴對話。後端 API 與資料庫由 `emochess_backend` 提供。

## 技術要點

- Flutter + Dart
- Provider 狀態管理
- GoRouter 導航
- 本地資料：SharedPreferences（少量偏好/使用者快取）、flutter_secure_storage（Token）
- 網路：http

## 本地啟動

1. 安裝依賴

```bash
flutter pub get
```

2. 指定後端 API Base URL（建議包含 `/api`；若只給網域會自動補成 `/api`）

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

App 不提供「App 內修改後端位址」的設定入口；後端位址只使用編譯/啟動時指定的 `API_BASE_URL`（或預設值：Release 會指向正式環境）。

## 設定參數

- API_BASE_URL：後端 API base URL（例如 `http://localhost:3000/api` 或 `https://literaryapi.beioverworked.com/api`）
 
AI 金鑰採正式產品作法：放在後端環境變數（例如 Coolify / Secrets），App 端不保存任何 AI 金鑰。

## 產出（Release Build）

- 預設（未指定 `API_BASE_URL` 時）：Release 會使用 `https://literaryapi.beioverworked.com/api`
- 覆寫正式環境（例如 staging）：`flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-domain>/api`
- Web：`flutter build web --release` → `build/web/`
  - 目前依賴 `flutter_secure_storage_web`，因此 Flutter WebAssembly（wasm）模式會出現 dry-run 不相容警示；不影響一般 Web release build。
- Android APK：`flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
- Android AAB（上架用）：`flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- iOS（需自行簽章）：`flutter build ios --release --no-codesign`

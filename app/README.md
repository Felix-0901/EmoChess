# EmoChess App

## 模組簡介

Flutter 應用程式，提供西洋棋對弈、情緒記錄、對局分析與互動式陪伴對話。後端 API 與資料庫由 `backend` 提供。

## 使用技術

- Flutter + Dart
- Provider 狀態管理
- GoRouter 導航
- 本地資料：SharedPreferences（少量偏好/使用者快取）、flutter_secure_storage（Token）
- 網路：http
- 棋力與規則：`chess`

## 資料夾結構

```text
app/
  lib/
    config/      # App 設定（API_BASE_URL 等）
    models/      # 資料模型
    providers/   # 狀態管理
    screens/     # 畫面
    services/    # API/商業邏輯
    storage/     # Token storage
    theme/       # 主題
    widgets/     # 共用元件
    main.dart
  assets/
  android/ ios/ macos/ windows/ linux/ web/
```

## 本地開發流程

1. 安裝依賴

```bash
flutter pub get
```

2. 指定後端 API Base URL（建議包含 `/api`；若只給網域，App 會自動補成 `/api`）

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

App 不提供「App 內修改後端位址」的設定入口；後端位址只使用編譯/啟動時指定的 `API_BASE_URL`（或預設值：所有模式都會指向正式環境，若要連本機請自行覆寫）。

## 環境變數

### `API_BASE_URL`

以 `--dart-define=API_BASE_URL=...` 注入，例如：

- `http://localhost:3000/api`
- `https://emochessapi.beioverworked.com/api`

若未提供 `API_BASE_URL`，App 會直接使用正式環境預設值（由 `lib/config/app_config.dart` 決定）：

- 所有模式：`https://emochessapi.beioverworked.com/api`

AI 金鑰採後端代呼叫作法：放在後端環境變數（例如部署平台的 Secrets），App 端不保存任何 AI 金鑰。

## 建置 / 啟動方式

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
```

## 部署細節

本專案以 Flutter App 為主，不規劃 Web 端對外使用；若需要 Web build 做內部測試，需留意後端 `CORS_ORIGIN` 設定（僅瀏覽器情境需要）。

## 產出（Release Build）

- 預設（未指定 `API_BASE_URL` 時）：App 會使用 `https://emochessapi.beioverworked.com/api`
- 覆寫正式環境（例如 staging）：`flutter build appbundle --release --dart-define=API_BASE_URL=https://<your-domain>/api`
- Web：`flutter build web --release` → `build/web/`
  - 目前依賴 `flutter_secure_storage_web`，因此 Flutter WebAssembly（wasm）模式會出現 dry-run 不相容警示；不影響一般 Web release build。
- Android APK：`flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
- Android AAB（上架用）：`flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- iOS（需自行簽章）：`flutter build ios --release --no-codesign`

## 常見問題

### API 連不上（模擬器 / 實機）

- 若要連正式後端，不必額外設定；未指定 `API_BASE_URL` 時會直接使用 `https://emochessapi.beioverworked.com/api`
- Android Emulator 要連本機後端時，請用 `http://10.0.2.2:3000/api`（不是 `localhost`）
- 實機要連本機後端時，請用 `http://<你的電腦區網IP>:3000/api`，並確認手機與電腦同網段

### 我可以在 App 內改後端位址嗎？

不行。App 不提供設定入口，後端位址只使用 `API_BASE_URL`（或預設值）。

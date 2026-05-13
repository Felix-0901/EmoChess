# iOS App Store 上架 Skill SOP 暫存紀錄

> 暫存檔案。用途是記錄本專案實戰上架流程、可自動化範圍、錯誤處理與未來 Skill 設計。等正式 Skill 建立完成後，刪除此檔。

## 目標

- 未來可透過「請使用 XXX Skill」啟動 iOS 上架流程。
- Skill 需支援 Flutter 與 React Native 專案。
- Skill 需能建立穩定的本機自動化檔案、等待使用者提供必要環境變數與登入資訊。
- Skill 需盡量使用 App Store Connect API、Transporter / fastlane 與專案內容分析完成上架前準備。
- 若需要 App Store Connect 網頁操作，使用 Codex 內建瀏覽器開頁並等待使用者登入，不使用本機 Chrome / Safari。
- 最終目標是讓使用者只需補圖片或人工確認後，就能送出審核。

## 來源與研究結論

### 已參考的本機文件

- `/Users/felix/Downloads/iOS 上架.md`
- 內容主軸：Flutter、rbenv、Bundler、fastlane、CocoaPods、App Store Connect API Key、`flutter build ipa`、`upload_to_testflight`。
- 可保留的實務經驗：
  - 不使用 macOS system Ruby。
  - `Gemfile` 同時放 `fastlane` 與 `cocoapods`。
  - `.ipa` 檔名不要寫死，應搜尋 `build/ios/ipa/*.ipa`。
  - `.p8` 不進 Git，不放專案。
  - Apple processing 需要等待，不能把等待中誤判為上傳失敗。

### 官方與工具文件重點

- Apple 上傳 build 可用 Xcode、Swift Playground、altool、Transporter，並可搭配 App Store Connect API JWT 驗證。build 進入 App Store Connect 後，Apple 會 processing，完成前不一定馬上顯示。
- Apple 會用 App bundle 內的 Bundle ID、Version Number、Build String 對應 App Store Connect 內的 App 與版本。
- App Store metadata、localization、screenshots、app previews 有 App Store Connect API 可操作，但部分初始設定與帳號狀態仍可能需要網頁。
- 送審前必須提供 required metadata 並選擇 build。網頁流程是 `Add for Review` 後再 `Submit for Review`。
- fastlane `upload_to_testflight` 可用 App Store Connect API Key，官方建議 API Key 優先於 Apple ID，因為不需要 2FA。
- fastlane `deliver` / `upload_to_app_store` 可維護 metadata、screenshots、App Preview、binary，並可 `submit_for_review`，但正式送審前仍應讓使用者確認。
- fastlane `deliver` metadata folder 支援 `name.txt`、`subtitle.txt`、`description.txt`、`keywords.txt`、`privacy_url.txt`、`release_notes.txt`、`support_url.txt`、`marketing_url.txt`、`promotional_text.txt`、review information 等檔案。
- Firecrawl CLI 本機可用，但目前未登入，搜尋時要求 Firecrawl account 或 `FIRECRAWL_API_KEY`。本輪改用一般網路查詢取得官方與 fastlane 文件。

參考連結：

- Apple Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Apple App Metadata API: https://developer.apple.com/documentation/appstoreconnectapi/app-metadata
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- Apple Upload screenshots and previews: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots
- fastlane upload_to_testflight: https://docs.fastlane.tools/actions/upload_to_testflight/
- fastlane upload_to_app_store / deliver: https://docs.fastlane.tools/actions/upload_to_app_store/
- fastlane app_store_connect_api_key: https://docs.fastlane.tools/actions/app_store_connect_api_key/

## 自動化邊界

### 優先使用 API / CLI 的項目

- 檢查專案類型：Flutter 或 React Native。
- 檢查 iOS 專案存在與可建置狀態。
- 檢查 Bundle ID、Team ID、Version、Build Number。
- 建立或更新 `Gemfile`、`ios/fastlane/Appfile`、`ios/fastlane/Fastfile`。
- 建立 `fastlane/metadata` 草稿檔。
- 透過專案 README、localization、首頁文字、設定頁、功能模組推導 App Store metadata 草稿。
- 建置 `.ipa`。
- 使用 fastlane / Transporter 上傳 build。
- 查詢 build processing 狀態。
- 以 API 或 fastlane 更新 App Store 版本資訊、localization、review info、價格與可用地區等可支援欄位。
- 可選：用 API / fastlane 上傳 screenshots 與 previews。

### 需要人工或瀏覽器協作的項目

- Skill 開始操作 Apple 後台前，必須先向使用者確認本次要使用哪個 Apple ID / Team / App Store Connect 帳戶。
  - 若使用者未確認帳戶，不建立 Bundle ID、不建立 App Record、不送審、不發布。
- Apple Developer / App Store Connect 初次登入、2FA。
- 首次建立 App Store Connect API Key 與下載 `.p8`。
- App Store Connect App Record 若 API 不支援建立，改用網頁。
- 需要使用者確認的外部可見操作：送出審核、正式發布、變更付費價格、移除 submission、發布 pre-order。
- 帳號協議、稅務、銀行、合規資料尚未完成時，需要人工處理。
- 隱私問卷、年齡分級、出口合規若資訊不足，需要使用者確認，不能自行猜測。
- 使用者指定「只上傳照片」時，Skill 應停在圖片上傳前或開網頁到對應位置等待使用者。

## 未來 Skill 觸發後的建議流程

### 1. 專案盤點

1. 讀取 `README.md`、子 README、`pubspec.yaml`、`package.json`、`app.json`、`app.config.*`、`ios/Runner.xcodeproj/project.pbxproj` 或 React Native iOS project。
2. 判斷框架：
   - Flutter：存在 `pubspec.yaml`，以 `flutter build ipa` 為主。
   - React Native：存在 `package.json` 且有 `react-native` / Expo 設定，依 Bare RN 或 Expo/EAS 分流。
3. 取得或要求確認：
   - 本次要使用的 Apple ID / App Store Connect 帳戶 / Team
   - App 名稱
   - Bundle ID
   - Apple Team ID
   - SKU
   - Primary Language
   - App Store Connect app id / apple id
   - 支援語系
   - 隱私政策 URL
   - 支援 URL
   - 後端正式 API URL
   - 審核用帳號與密碼，若 App 需要登入

### 2. 檔案與環境準備

1. 建立 `.gitignore` 規則，確保 `.p8`、`.env`、API key JSON 不進 Git。
2. 建立 `Gemfile`：
   - `fastlane`
   - `cocoapods`
3. 建立 `ios/fastlane/Appfile`。
4. 建立 `ios/fastlane/Fastfile`，至少包含：
   - `beta`：build + TestFlight 上傳。
   - `metadata`：只推 metadata，不送審。
   - `submit_review_prepare`：選 build、補送審資訊，但送審前要求確認。
5. 建立環境變數範例檔，例如 `.env.appstore.example`，只放鍵名不放值。
6. 等待使用者提供環境變數：
   - `APP_STORE_CONNECT_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_PRIVATE_KEY` 或安全的 key filepath
   - `APP_STORE_CONNECT_TEAM_ID`，若需要
   - `APP_IDENTIFIER`
   - `APPLE_ID` / App Store Connect app id，若 fastlane 需要

### 3. Metadata 生成策略

1. 先讀專案內容，不憑空編造。
2. 優先來源：
   - 根 README / app README
   - `lib/l10n`、`assets/locales`、`src/i18n`
   - App 首頁、設定頁、功能頁字串
   - 後端 API README 中的核心功能描述
3. 產生語系：
   - 有繁中內容時建立 `zh-Hant`。
   - 有英文內容時建立 `en-US`。
   - 沒有某語系實際內容時，可產生草稿但標記為需人工確認。
4. 需產出的檔案：
   - `ios/fastlane/metadata/<locale>/name.txt`
   - `subtitle.txt`
   - `description.txt`
   - `keywords.txt`
   - `privacy_url.txt`
   - `support_url.txt`
   - `marketing_url.txt`，若有
   - `promotional_text.txt`
   - `release_notes.txt`
   - `ios/fastlane/metadata/review_information/*.txt`
5. 文案規則：
   - 不誇大醫療、療癒、診斷效果。
   - 若 App 與兒童、自閉症、心理健康、AI 陪伴有關，使用保守描述。
   - 不承諾治療或專業醫療效果。
   - 若涉及帳號、AI、資料上傳，隱私描述需與實際資料收集一致。

### 4. Privacy / Support 頁面策略

1. Skill 應先判斷是否已有正式後端或網站網域。
   - 優先從使用者提供的 production domain、README、Coolify 設定、App config、API base URL 推導。
   - 後端通常已部署完成後才會使用此 Skill，因此優先檢查 production domain。
2. 檢查公開頁面是否存在：
   - `GET https://<domain>/privacy`
   - `GET https://<domain>/support`
   - 需回傳 `200`，且 Content-Type 應為 HTML 或可公開閱讀的頁面。
   - 不可需要登入，不可是 Google Doc/Notion 等臨時文件作為正式長期方案，除非使用者明確要求短期替代。
3. 若頁面不存在，依專案型態建立：
   - Express / Node 後端：新增公開 route，例如 `/privacy`、`/support`。
   - Next.js / web 前端：新增 app/page 或 pages route。
   - 其他後端：依既有框架最小侵入方式新增公開 HTML route。
4. 內容生成原則：
   - 以英文為主，適合 App Store 審核與國際使用者閱讀。
   - 讀取專案 README、App 功能、登入/資料模型、後端 API、AI 使用方式後撰寫。
   - 隱私權政策需提到實際收集/處理資料，例如帳號、棋局、情緒打卡、AI 對話/分析、技術紀錄。
   - 支援頁需提供支援信箱、問題回報建議資訊、帳號/資料刪除請求方式、隱私權政策連結。
   - 避免未確認的公司地址、電話、統編等資訊；若需要再向使用者詢問。
   - 對兒童、ASD、心理健康、AI 陪伴相關 App，使用保守語氣，不宣稱醫療、診斷或治療效果。
5. 建立後需驗證：
   - 專案 build / typecheck 通過。
   - 本機啟動後 `/privacy`、`/support` 回傳 `200 text/html`。
   - 更新 `.env.appstore.local` 或 metadata URL：
     - `APP_PRIVACY_URL=https://<domain>/privacy`
     - `APP_SUPPORT_URL=https://<domain>/support`
     - 若 domain 本身也是產品頁，`APP_MARKETING_URL=https://<domain>`。

### 5. Build 與上傳

#### Flutter

1. `flutter doctor -v`
2. `flutter pub get`
3. 確認 `pubspec.yaml` version，例如 `1.0.0+1`。
4. release build 必須注入正式 API：
   - `flutter build ipa --release --dart-define=API_BASE_URL=https://<正式後端網域>/api`
5. 找出 `.ipa`：
   - `build/ios/ipa/*.ipa`
6. `bundle exec fastlane beta`

#### React Native Bare

1. 檢查 `ios/Podfile`。
2. `bundle exec pod install` 或 `cd ios && pod install`。
3. 透過 fastlane `gym` / `build_app` 建置。
4. 透過 `upload_to_testflight` 上傳。

#### Expo / EAS

1. 判斷是否有 `app.json`、`app.config.js`、`eas.json`。
2. 優先使用 EAS build / submit，或要求使用者確認是否要轉成本機 iOS build。
3. 若使用 EAS，Skill 應另外記錄 Expo token / Apple 認證需求，不混用 Flutter 流程。

### 6. App Store Connect 網頁協作

1. 需要網頁時，使用 Codex 內建瀏覽器。
2. 開啟 App Store Connect 並停在登入畫面或目標 App 頁面。
3. 等待使用者登入與完成 2FA。
4. 登入後，Codex 可協助填寫尚未由 API 完成的欄位。
5. 任何送出審核、發布、取消送審、價格變更前，先停下要求使用者明確確認。

## EmoChess 目前觀察

- 專案路徑：`/Users/felix/Documents/黑克松/EmoChess`
- 架構：monorepo，`app/` 是 Flutter，`backend/` 是 Node.js + Express + Prisma。
- App 功能：西洋棋、情緒打卡、對局分析、AI 陪伴對話、帳號登入、雲端棋局紀錄。
- App localization：目前有英文與繁中手寫 localization。
- `app/pubspec.yaml` 目前版本：`1.0.0+1`。
- iOS Bundle ID 已改為 `com.beioverworked.students.emochess`。
- iOS Team ID 目前可在 Xcode project 看到 `S3DSU79C4X`，仍需由使用者確認是否為正確上架 team。
- `Info.plist` 顯示名稱目前是 `Emochess App`，可能需調整為 `EmoChess`。
- App 正式 build 需要 `--dart-define=API_BASE_URL=https://<正式後端網域>/api`，不能使用 placeholder。
- App 需要登入；送審前很可能需要提供 demo account 或 review note。
- AI 金鑰不在 App 端，App 透過後端 JWT 呼叫 AI API。metadata 與審核說明應反映這點。
- 後端已新增英文公開頁：
  - `https://emochess.beioverworked.com/privacy`
  - `https://emochess.beioverworked.com/support`
- App Store 上架環境檔目前可確定的值：
  - `APP_IDENTIFIER=com.beioverworked.students.emochess`
  - `APPLE_TEAM_ID=S3DSU79C4X`
  - `IOS_RELEASE_API_BASE_URL=https://emochess.beioverworked.com/api`
  - `APP_PRIVACY_URL=https://emochess.beioverworked.com/privacy`
  - `APP_SUPPORT_URL=https://emochess.beioverworked.com/support`
  - `APP_MARKETING_URL=https://emochess.beioverworked.com`

## EmoChess 預估 App Store metadata 草稿方向

> 這只是方向，不是最終文案。正式填寫前需重新讀取最新程式與 README。

- 類別候選：
  - `GAMES`，子類別可考慮 `GAMES_BOARD` 或 `GAMES_STRATEGY`。
  - 若更強調學習，可評估 `EDUCATION` 作為主類別，但棋局互動與遊戲屬性較強。
- 中文定位：
  - 以西洋棋為核心的情緒陪伴與學習 App。
  - 透過對局前情緒打卡、遊戲中陪伴訊息與對局後分析，協助使用者觀察情緒變化。
- 英文定位：
  - A chess-based emotional learning companion with check-ins, supportive prompts, and post-game reflection.
- 敏感描述注意：
  - 避免宣稱治療 ASD、焦慮、情緒障礙。
  - 可描述為 learning、reflection、supportive companion，不寫 clinical / therapy claim。

## 錯誤紀錄政策

- 這份暫存檔在實戰中可記錄錯誤、原因、修正方式。
- 若後續成功完成同一問題，保留「穩定解法」，移除原始錯誤雜訊與失敗 log。
- 最終 Skill 只保留可重複執行的 SOP，不保留一次性的錯誤訊息。

## 實戰紀錄

### 2026-05-13 初始規劃

- 已閱讀舊版 `iOS 上架.md`。
- 已檢查 EmoChess 專案結構、README、Flutter app README、`pubspec.yaml`、iOS project 設定。
- 已查詢 Apple 與 fastlane 目前文件。
- 已建立本暫存 SOP。
- 已建立 `app/.ruby-version`，固定 Ruby `3.3.0`。
- 已建立 `app/Gemfile` 與 `app/Gemfile.lock`，鎖定 fastlane / CocoaPods 依賴。
- 已建立 `app/.env.appstore.example`，只放鍵名與範例值，不放任何金鑰。
- 已建立 `app/ios/fastlane/Appfile` 與 `app/ios/fastlane/Fastfile`。
- 已建立 `app/ios/fastlane/metadata/en-US` 與 `app/ios/fastlane/metadata/zh-Hant` metadata 草稿。
- 已驗證 fastlane lane 可正常解析：
  - `ios doctor`
  - `ios build_ipa`
  - `ios beta`
  - `ios metadata`
- 已驗證 `ios doctor` lane 成功，環境為 Flutter `3.41.9`、Xcode `26.4`、CocoaPods `1.16.2`、fastlane `2.234.0`。
- 已驗證 `flutter analyze` 成功。
- 已驗證 `flutter test` 成功。
- 已驗證 iOS no-codesign release build 成功：
  - `flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://api.example.invalid/api`
- `ios build_ipa` 已設計為在缺少 `IOS_RELEASE_API_BASE_URL` 時停止，避免產生錯誤正式 build。
- `ios metadata` 已設計為在缺少 `APP_PRIVACY_URL` 或 `APP_SUPPORT_URL` 時停止，避免推送空白公開連結。
- 本輪尚未登入 App Store Connect。
- 本輪尚未修改 Bundle ID。
- 本輪尚未產生或上傳正式 IPA。

### 2026-05-13 建立 App Store 公開頁

- 使用者確認 Coolify production domain 為 `https://emochess.beioverworked.com`。
- 已在 Express 後端新增英文公開頁 route：
  - `GET /privacy`
  - `GET /support`
- 頁面內容以英文為主，適合 App Store Connect 的 Privacy Policy URL 與 Support URL。
- 隱私權政策明確描述：
  - 帳號資料
  - 棋局資料
  - 情緒打卡資料
  - AI 互動與分析資料
  - 技術紀錄
  - 不提供醫療、診斷或治療服務
  - 不販售個資、目前不做第三方廣告追蹤
  - 兒童與監護人資料請求方式
- 支援頁包含：
  - 支援信箱 `beioverworked@gmail.com`
  - 問題回報建議資訊
  - 帳號與資料查詢/更正/刪除請求方式
  - Privacy Policy 連結
- 已更新 `backend/README.md` API 端點與部署文件。
- 已更新 `app/.env.appstore.local`：
  - `APP_PRIVACY_URL=https://emochess.beioverworked.com/privacy`
  - `APP_SUPPORT_URL=https://emochess.beioverworked.com/support`
  - `APP_MARKETING_URL=https://emochess.beioverworked.com`
- 已驗證：
  - `npm run build` 成功。
  - 本機 `GET /privacy` 回傳 `200 text/html`。
  - 本機 `GET /support` 回傳 `200 text/html`。
- 未來 Skill 應內建此檢查：若專案上架前沒有 `/privacy` 與 `/support`，且可識別後端或網站入口，就依專案內容自行建立英文正式頁，再驗證並寫入 App Store metadata URL。

### 2026-05-13 建立 Apple 後台資源

- 已確認本機 `app/.env.appstore.local` 可正常 source，且：
  - `APP_IDENTIFIER=com.beioverworked.students.emochess`
  - `APPLE_TEAM_ID=S3DSU79C4X`
  - `APP_STORE_CONNECT_KEY_ID` 已設定
  - `APP_STORE_CONNECT_ISSUER_ID` 已設定
  - `.p8` 檔案存在
- 已將 iOS project 的 Bundle ID 改為正式值：
  - Runner：`com.beioverworked.students.emochess`
  - RunnerTests：`com.beioverworked.students.emochess.RunnerTests`
- 已將 iOS `Info.plist` 顯示名稱調整為 `EmoChess`。
- 已透過 App Store Connect API / Spaceship 建立 Apple Developer Bundle ID：
  - Bundle ID：`com.beioverworked.students.emochess`
  - Apple resource id：`KCU9TGM94G`
  - Name：`EmoChess`
  - Platform：API 回傳 `UNIVERSAL`
- 已嘗試用 API 建立 App Store Connect App Record：
  - Name：`EmoChess`
  - SKU：`com.beioverworked.students.emochess`
  - Primary locale：`en-US`
  - Version：`1.0.0`
  - Platform：`IOS`
- Apple API 回覆目前此 API Key 對 `apps` resource 不允許 `CREATE`，只允許 `GET_COLLECTION`、`GET_INSTANCE`、`UPDATE`。
- 結論：此帳號/Key 可用 API 查詢與更新，但 App Store Connect App Record 初建需改用 App Store Connect 網頁完成。未來 Skill 應先嘗試 API；若遇到此權限限制，改用 Codex 內建瀏覽器開到 App Store Connect，等待使用者登入與 2FA 後建立 App Record。
- 使用者確認本次使用已登入的 App Store Connect 帳戶操作，並要求未來 Skill 啟動時需先確認要使用哪個 Apple ID 帳戶。
- 已透過 Codex 內建瀏覽器在 App Store Connect 建立 App Record：
  - 登入帳戶畫面顯示：`旻憲 李 / MIN HSIEN LI`
  - App name：`EmoChess`
  - Platform：`iOS`
  - Primary language：`英文（美國）` / `en-US`
  - Bundle ID：`EmoChess - com.beioverworked.students.emochess`
  - SKU：`com.beioverworked.students.emochess`
  - User access：`完整存取權限`
  - App Store Connect Apple ID：`6768895600`
- 已將 `app/.env.appstore.local` 的 `APP_STORE_APPLE_ID` 回寫為 `6768895600`。
- 已再次用 API 查詢確認：
  - App：`6768895600` / `EmoChess` / `com.beioverworked.students.emochess` / `en-US`
  - Bundle ID resource：`KCU9TGM94G` / `com.beioverworked.students.emochess`
- 已執行 `fastlane ios metadata` 推送 App Store 文字內容：
  - `en-US` 與 `zh-Hant` localized metadata 已開始上傳。
  - `privacy_url.txt`、`support_url.txt`、`marketing_url.txt` 已由 env 寫入 metadata 目錄。
  - 初次遇到 fastlane HTML Preview 在非互動環境要求確認，穩定解法是在 metadata lane 設定 `force: true`。
  - 後續遇到 App Store Connect API Key precheck 無法檢查 IAP，穩定解法是在 metadata lane 設定 `run_precheck_before_submit: false`。
  - 最後 Apple 要求 App Review Contact 必填：`contactFirstName`、`contactLastName`、`contactEmail`、`contactPhone`，且電話需使用 `+國碼` 格式。未來 Skill 應在 metadata 推送前先詢問並填入 `review_information`，不能自行猜測電話。
- 已調整 metadata lane：
  - `review_information` 不再提交到 Git，避免未來把審核聯絡人電話、Email 或 demo account 放進版本庫。
  - 未提供 `APP_REVIEW_*` 環境變數時，lane 會移除本機 `review_information` 目錄並跳過 review information。
  - 若提供部分 `APP_REVIEW_*`，lane 會直接報錯，要求補齊。
- 已成功執行 `fastlane ios metadata`，可填的 App Store metadata 已推送完成。
- 已成功執行 `fastlane ios beta`：
  - Build：`1.0.0 (1)`
  - IPA：`app/build/ios/ipa/EmoChess.ipa`
  - App Store Connect App ID：`6768895600`
  - 上傳成功，Apple processing 完成。
  - 已設定 TestFlight changelog。
  - 已分發給 Internal testers。
  - Xcode / Flutter build warning：
    - Launch image 仍是 Flutter 預設 placeholder，正式送審前建議替換。
    - fastlane 建議在 `Info.plist` 設定 `ITSAppUsesNonExemptEncryption=false` 以減少 export compliance 等待；本專案已加入此 key，與 lane 中的 `uses_non_exempt_encryption: false` 一致。
- 使用者已提供 App Review Contact。資料已寫入本機 ignored 的 `app/.env.appstore.local`，不寫入 Git、不寫入 SOP 明文。
- 已重新執行 `fastlane ios metadata`，App Review Contact 已成功推送到 App Store Connect。
- 已透過 Codex 內建瀏覽器完成並發佈 App Privacy：
  - 先判斷本專案有資料收集，因為 App 會透過後端處理帳號登入、雲端棋局紀錄、情緒紀錄、AI 聊天與報告。
  - Privacy Policy URL：`https://emochess.beioverworked.com/privacy`
  - 選取 7 種資料類型：`電子郵件地址`、`遊戲內容`、`其他使用者內容`、`使用者識別碼`、`產品互動`、`其他使用狀況資料`、`其他診斷資料`。
  - `電子郵件地址`、`使用者識別碼`、`其他診斷資料` 用途設為 `App 功能`。
  - `遊戲內容`、`其他使用者內容`、`產品互動`、`其他使用狀況資料` 用途設為 `App 功能` 與 `產品個人化`。
  - 所有已選資料類型皆設為 `會與使用者身分連結`。
  - 所有已選資料類型皆設為 `不會用於追蹤用途`。
  - 頁面顯示已由登入帳戶於數秒鐘前發佈。
- 已透過 Codex 內建瀏覽器補齊 App Store Connect 其他可自動處理項目：
  - App Store 版本頁：版權填入 `© 2026 Beioverworked. All rights reserved.`。
  - App Store 版本頁：發佈方式改為 `手動發佈此版本`，避免通過審核後自動上架。
  - App 資訊：類別改為 `遊戲`，子類別為 `桌上遊戲`、`策略遊戲`，次要類別為 `教育`。
  - App 資訊：內容版權聲明為不包含、顯示或存取第三方內容。
  - 年齡分級：完成問卷，App Store 顯示 `9+`；醫療或治療資訊為無，健康或保健主題為是。
  - 受監管醫療器材：聲明此 App 不是任何國家或地區的受監管醫療器材。
  - App 輔助使用：iPhone / iPad 先標示支援 `不僅以顏色來區分` 與 `足夠對比度`；因 App 尚未正式上架，該頁的發佈按鈕目前不可用。
  - App Store 版本頁：已選取 build `1.0.0 (1)`，後續因 Launch Screen 修正改選 build `1.0.0 (2)`。
- 已修正 iOS Launch Screen：
  - 將 Flutter 預設 1x1 transparent `LaunchImage` 替換為 EmoChess app icon 產生的 1x / 2x / 3x 圖檔。
  - Launch Screen 背景改為 App 的淡青色背景。
  - `app/pubspec.yaml` build number 從 `1.0.0+1` bump 為 `1.0.0+2`。
  - `flutter analyze` 成功。
  - `flutter test` 成功。
  - 已執行 `fastlane ios beta`，build `1.0.0 (2)` 成功上傳、processing 完成，並分發給 Internal testers。
  - 已透過 App Store Connect API 將 App Store version `1.0` 指向 build `1.0.0 (2)`。
- Bundle ID 變更後已重新驗證：
  - `flutter analyze` 成功。
  - `flutter test` 成功。
  - `backend npm run build` 成功。
- 已處理並上傳 App Store screenshots：
  - 使用者提供 5 張 iPhone 截圖，原始尺寸為 `1179 x 2556`。
  - 轉換為 App Store Connect 可接受的 iPhone 6.5 吋尺寸 `1242 x 2688`，輸出為 8-bit RGB PNG。
  - 截圖放入 `app/ios/fastlane/screenshots/en-US` 與 `app/ios/fastlane/screenshots/zh-Hant`；目前繁中版本先沿用英文截圖。
  - 執行 `UPLOAD_SCREENSHOTS=true fastlane ios metadata` 成功上傳 screenshots，不送審。
  - App Store Connect 頁面重新整理後顯示 `共 5 張截圖（最多 10 張）`。
- Demo account 注意事項：
  - `fastlane ios metadata` 會依 `app/.env.appstore.local` 產生本機 ignored 的 `fastlane/metadata/review_information`。
  - 若 `APP_REVIEW_DEMO_USER` 與 `APP_REVIEW_DEMO_PASSWORD` 留空，重新推 metadata 可能會把 App Store Connect 的「需要登入」狀態覆蓋回未勾選。
  - 已將 demo account 欄位補回本機 ignored env，並重新推送 App Review Information。
  - App Store Connect 頁面已確認「需要登入」為已勾選，且 demo account 欄位存在。
  - 未來 Skill 在執行 metadata lane 前，必須檢查 demo account 欄位；若 App 需要登入且未提供 demo account，應停下詢問使用者，不應以空值覆蓋線上設定。

## 未解問題

- 正式 Bundle ID：`com.beioverworked.students.emochess`
- App Store Connect App Record 已建立：`6768895600`
- Apple Developer Team / Team ID：`S3DSU79C4X`
- App Store Connect API Key 已建立並已可用於查詢 / 更新；不具備 `apps CREATE` 權限。
- 正式後端 API URL：`https://emochess.beioverworked.com/api`
- Privacy Policy URL：`https://emochess.beioverworked.com/privacy`
- Support URL：`https://emochess.beioverworked.com/support`
- App Privacy：已完成並發佈；未來 Skill 需先掃描專案資料流，再產生建議填答並讓使用者確認高風險資料分類。
- App Store version build：已選取 `1.0.0 (2)`。
- App Store screenshots：iPhone 6.5 吋已上傳 5 張，`en-US` 與 `zh-Hant` 皆已提供。
- 審核用 demo account：已在 App Store Connect 勾選需要登入並填入；憑證只保存在本機 ignored env，不寫入 Git 或 SOP 明文。
- App Review Contact：已由使用者提供並推送完成；未來 Skill 仍需在啟動時向使用者確認或要求填寫。
- 最終是否只準備到「可按送審」，還是要在確認後由 Skill 點擊 / API 送出審核？

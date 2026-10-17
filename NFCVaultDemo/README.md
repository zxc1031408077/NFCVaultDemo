# NFCVaultDemo

可在 Xcode 26 / iOS 26.6.1 SDK 開啟的 SwiftUI + Core NFC 範例 App。

部署目標設為 iOS 17.0，沒有依賴 iOS 26 專屬 API，因此可在 iOS 26.6.1 實機執行。

## 功能

- 掃描並解析 NDEF 訊息
- 把掃描結果儲存成卡片資料檔案
- 顯示 record type、payload hex 與可讀文字
- 匯出 JSON 分享檔
- App 內的「本地測試模擬」：產生短期測試 token，供 UI/流程驗證

## iOS NFC 邊界

這個專案使用公開的 Core NFC reader API。它不讀取或重建門禁系統的密鑰、加密區塊，也不把真實門禁憑證送入無線仿真流程。iOS 上的 `CardSession`/HCE 需要 Apple 管理的 entitlement 與特定交易資格；它不是任意 NFC 磁扣複製介面。

## 在 macOS 建置

1. 用 Xcode 26 開啟 `NFCVaultDemo.xcodeproj`。
2. 在 Signing & Capabilities 選取自己的 Team 與 Bundle Identifier。
3. 將實機連接到 Xcode；Core NFC 需要支援 NFC 的 iPhone，Simulator 不提供實際讀卡。
4. 在實機上執行，按「掃描 NDEF」並把標籤貼近 iPhone 上方。
5. 封裝 IPA 時使用自己的 Apple Developer signing profile。

## 命令列封裝

1. 將 `ExportOptions.development.example.plist` 複製成 `ExportOptions.development.plist`。
2. 把 `YOUR_TEAM_ID` 換成 Apple Developer Team ID。
3. 在 macOS Terminal 執行：

```bash
chmod +x NFCVaultDemo/build_ipa.sh
./NFCVaultDemo/build_ipa.sh
```

輸出會放在 `build/export/`。若要給已登錄 UDID 的實機，將 plist 的 `method` 改成 `ad-hoc`，並在 Apple Developer 帳號中登錄該裝置。

## Windows 封裝既有 .app

Windows 可以把已完成編譯與簽名的 `.app` 包成 IPA 容器：

```powershell
powershell -ExecutionPolicy Bypass -File .\NFCVaultDemo\pack_ipa.ps1 `
  -AppPath "C:\path\to\NFCVaultDemo.app" `
  -OutputPath ".\NFCVaultDemo.ipa"
```

這一步只處理 Payload/ZIP 結構；Swift 編譯、Apple SDK 與簽名先由 macOS/Xcode 或 macOS CI 完成。

`Info.plist` 已包含 NFC reader usage description，entitlements 已宣告 NDEF reader 格式。


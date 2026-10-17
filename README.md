# NFCVaultDemo

這個工作區包含一個 SwiftUI + Core NFC 的 iOS App，以及 Windows 端觸發 macOS CI 建置 IPA 的流程。

## Windows 完整操作流程

1. 把本資料夾上傳到 GitHub repository。
2. 在 GitHub 的 `Actions` 頁面選擇 `Build unsigned IPA`。
3. 按 `Run workflow`。
4. 工作完成後下載 Artifact：`NFCVaultDemo-unsigned-ipa`。
5. 在 Windows 用 iLoader 匯入 IPA，完成簽名與安裝。

Workflow 檔案：`.github/workflows/build-unsigned-ipa.yml`。

## 本機 Windows 封裝

若已有由 macOS/Xcode 或 CI 產生的 `.app`：

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\NFCVaultDemo\pack_ipa.ps1 `
  -AppPath "C:\path\to\NFCVaultDemo.app" `
  -OutputPath ".\NFCVaultDemo.ipa"
```

## 功能範圍

- Core NFC NDEF 掃描與解析
- 本機卡片資料庫
- JSON 匯出
- App 內測試 token 模擬

實際門禁憑證、私有密鑰與射頻仿真流程未放入這個公開 API 專案。


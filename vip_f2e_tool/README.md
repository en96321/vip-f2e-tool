# VIP F2E Tool

整合 PR 比對、RedPen CI、發車工具的前端開發工具。

## 功能

- **PR Commit 比對**: 比對 Staging 和 Production PR 的 commit，確認 cherry-pick 是否完整
- **RedPen CI**: 靜態程式碼分析工具，掃描多個 Repository 的程式碼品質
- **發車工具**: Cherry-pick 發車工具，批次處理多個 commit 到目標分支

## 安裝

### 透過 Homebrew (推薦)

```bash
brew tap en96321/vip-f2e-tool
brew install --cask vip-f2e-tool
```

### 手動安裝

從 [Releases](https://github.com/en96321/vip-f2e-tool/releases) 下載最新的 DMG 檔案。

## 依賴

- [GitHub CLI (gh)](https://cli.github.com/) - 需先登入: `gh auth login`
- Git

## 開發

### 環境需求

- Flutter SDK ^3.10.4
- macOS

### 執行開發版本

```bash
flutter run -d macos
```

### 打包發佈

```bash
# 1. 建置 macOS Release
flutter build macos

# 2. 準備 DMG 來源目錄 (使用 ditto 保留 symlinks，避免檔案過大)
rm -rf build/dmg_source && mkdir -p build/dmg_source
ditto "build/macos/Build/Products/Release/VIP F2E Tool.app" "build/dmg_source/VIP F2E Tool.app"

# 3. 建立 DMG (需先安裝 create-dmg)
# brew install create-dmg
create-dmg --volname "VIP F2E Tool" --app-drop-link 200 200 "VIP_F2E_Tool_<VERSION>.dmg" "build/dmg_source"
```

### 更新 Homebrew Cask

發佈新版本後，更新 `homebrew/vip-f2e-tool.rb`:

1. 更新 `version` 號碼
2. 更新 `sha256` (執行 `shasum -a 256 <dmg_file>`)
3. 上傳 DMG 到 GitHub Releases

## 檢查更新

應用程式內建更新檢查功能，會透過 Homebrew 檢查並安裝更新。

```bash
# 手動更新
brew update && brew upgrade --cask vip-f2e-tool
```

## License

MIT

# Documentation: https://docs.brew.sh/Cask-Cookbook
# VIP F2E Tool Homebrew Cask

cask "vip-f2e-tool" do
  version "1.0.0"
  sha256 "a51b2bbea843ffc689340fd2cce969862bfb66fceff157cf3ac14f8174799d70"

  url "https://github.com/en96321/vip-f2e-tool/releases/download/v#{version}/VIP-F2E-Tool-#{version}.dmg"
  name "VIP F2E Tool"
  desc "整合 PR 比對、RedPen CI、發車工具的前端開發工具"
  homepage "https://github.com/en96321/vip-f2e-tool"

  depends_on formula: "gh"

  app "VIP F2E Tool.app"

  zap trash: [
    "~/Library/Preferences/com.en96321.vipF2eTool.plist",
    "~/Library/Application Support/com.en96321.vipF2eTool",
    "~/Library/Caches/com.en96321.vipF2eTool",
  ]

  caveats <<~EOS
    安裝完成後，請確認 GitHub CLI 已登入：
      gh auth login

    檢查更新：
      brew update && brew upgrade --cask vip-f2e-tool
  EOS
end

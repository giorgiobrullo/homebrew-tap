cask "cider-together" do
  version "1.1.0"
  sha256 "9bb47de5f04560e42250ee7d737966f4f1e125e54a77c397395964ec552aede2"

  url "https://github.com/giorgiobrullo/cider-listen-together/releases/download/v#{version}/CiderTogether-#{version}.dmg"
  name "CiderTogether"
  desc "Listen to music together with friends using Cider"
  homepage "https://github.com/giorgiobrullo/cider-listen-together"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "CiderTogether.app"

  zap trash: [
    "~/Library/Application Support/CiderTogether",
    "~/Library/Preferences/giorgiobrullo.com.CiderTogether.plist",
    "~/Library/Caches/giorgiobrullo.com.CiderTogether",
  ]
end

cask "cider-together" do
  version "1.0.0"
  sha256 "e5dcd92abbe2cf518ceaaed34a4615ba2f45ce14574e2aeedaa70233d78d8001"

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

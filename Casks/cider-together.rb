cask "cider-together" do
  version "1.0.1"
  sha256 "4f23ef4d5ec92d37a5c0bc2a71b795c2de454d75f8cf75915c4ca5d136f0c26c"

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

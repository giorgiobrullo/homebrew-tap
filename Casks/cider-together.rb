cask "cider-together" do
  version "1.0.1"
  sha256 "1a3dfa7fb5bd703cedb1188db6c9514769fc11cbfcf8371236c7d2267d2aa76a"

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

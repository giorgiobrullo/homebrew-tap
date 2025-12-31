cask "cider-together" do
  version "1.0.2"
  sha256 "beb8f4ed19dfed483c4102c0c7860eeee3312fb5e007d0c09d3f3b74c9e7749b"

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

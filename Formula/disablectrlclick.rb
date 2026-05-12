class Disablectrlclick < Formula
  desc "Menubar utility that disables Ctrl+Click as right-click on macOS"
  homepage "https://github.com/achendev/DisableCtrlClick"
  license "MIT"
  head "https://github.com/achendev/DisableCtrlClick.git", branch: "master"

  depends_on :macos

  def install
    system "./build.sh"
    prefix.install "DisableCtrlClick.app"
  end

  def caveats
    <<~EOS
      The app bundle is installed at:
        #{opt_prefix}/DisableCtrlClick.app

      To make it visible to Launchpad/Spotlight and run it like a normal app,
      symlink it into /Applications (remove any existing copy first):
        rm -rf /Applications/DisableCtrlClick.app
        ln -sfn #{opt_prefix}/DisableCtrlClick.app /Applications/DisableCtrlClick.app
        open /Applications/DisableCtrlClick.app

      Grant Accessibility and Input Monitoring in System Settings on first launch.

      If permissions get stuck after a rebuild:
        tccutil reset Accessibility com.usr.DisableCtrlClick
        tccutil reset ListenEvent  com.usr.DisableCtrlClick

      To upgrade to the latest commit on master:
        brew upgrade --fetch-HEAD giorgiobrullo/tap/disablectrlclick
    EOS
  end

  test do
    assert_path_exists prefix/"DisableCtrlClick.app/Contents/MacOS/DisableCtrlClick"
  end
end

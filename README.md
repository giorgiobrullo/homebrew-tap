# Homebrew Tap

[![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black)](https://brew.sh/)
[![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/macos/)

Personal Homebrew tap for macOS apps and tools I use.

This is a third-party tap, not part of homebrew-core. Nothing here goes through Homebrew's review process, so audit the source before you install if you care. Each entry below links to the upstream project so you can check what you are running.

## Add the tap

```bash
brew tap giorgiobrullo/tap
```

## Available items

### Casks (prebuilt)

Casks pull a signed DMG or zip from the upstream release and drop the app into `/Applications`. They update when the upstream project cuts a new release.

| App | Source | Install |
|-----|--------|---------|
| CiderTogether | [giorgiobrullo/cider-listen-together](https://github.com/giorgiobrullo/cider-listen-together) | `brew install --cask giorgiobrullo/tap/cider-together` |

### Formulae (built from source)

Formulae here build the app locally from the upstream git repo. They are HEAD-only, which means there is no pinned stable version. Every install and every `--fetch-HEAD` upgrade clones whatever is currently on the upstream default branch and builds that. If upstream pushes something broken, you will build something broken. The build is reproducible by reading the formula and `build.sh` upstream.

| Tool | Source | Branch | Install |
|------|--------|--------|---------|
| DisableCtrlClick | [achendev/DisableCtrlClick](https://github.com/achendev/DisableCtrlClick) | `master` | `brew install --HEAD giorgiobrullo/tap/disablectrlclick` |

After install, follow the caveats printed by brew. The `.app` lands in the Cellar and you symlink it into `/Applications` yourself, since formulae cannot place files there directly.

## Updates

For casks, when upstream cuts a new release:

```bash
brew upgrade --cask
```

For HEAD formulae, refetch the upstream branch and rebuild:

```bash
brew upgrade --fetch-HEAD giorgiobrullo/tap/disablectrlclick
```

A plain `brew upgrade` will not pull new commits for HEAD formulae. The `--fetch-HEAD` flag is required.

## Notes on the formula approach

Homebrew's official guidance is that GUI apps should ship as casks, not formulae, and that formulae should pin a stable upstream version rather than tracking HEAD. Both rules are documented in [Acceptable Formulae](https://docs.brew.sh/Acceptable-Formulae). The DisableCtrlClick entry breaks both on purpose, because I wanted a brew-managed install that follows upstream `master` rather than the last tagged release. This is fine for a personal tap, and it would not be accepted into homebrew-core.

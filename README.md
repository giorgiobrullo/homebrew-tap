# Homebrew Tap

[![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black)](https://brew.sh/)
[![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/macos/)

Personal Homebrew tap for macOS and Linux utilities.

## Usage

### Add the tap

```bash
brew tap giorgiobrullo/tap
```

### Install apps and formulae

```bash
brew install --cask <app-name>
brew install <formula-name>
```

## Available Apps

| Name | Description | Install |
|------|-------------|---------|
| [CiderTogether](https://github.com/giorgiobrullo/cider-listen-together) | Listen to music together with friends using Cider | `brew install --cask cider-together` |
| tailscale-patched | Tailscale CLI daemon with a per-profile `--allow-public-inbound` toggle for personal routed-prefix/BGP setups | `brew install tailscale-patched` |

## tailscale-patched

This formula builds Tailscale from the upstream stable tag with a patch that adds:

```bash
tailscale-patched set --allow-public-inbound=true
tailscale-patched set --allow-public-inbound=false
```

The setting is stored in Tailscale prefs for the active profile/network and is off by default. When enabled, inbound packets received from tailnet peers are allowed through even when their original source IP is not a tailnet IP.

The CLI is installed as `tailscale-patched` so it can coexist with the official Tailscale app's `tailscale` wrapper. Do not run both daemons at the same time; quit/disable the official app before starting this service.

Start the daemon as root for real TUN/utun mode:

```bash
sudo brew services start tailscale-patched
```

## One-liner

Install any app directly without adding the tap first:

```bash
brew install --cask giorgiobrullo/tap/cider-together
brew install giorgiobrullo/tap/tailscale-patched
```

## Updates

Apps are automatically updated when new releases are published. Run:

```bash
brew upgrade --cask
```

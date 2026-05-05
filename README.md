# Homebrew Tap

[![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=for-the-badge&logo=homebrew&logoColor=black)](https://brew.sh/)
[![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/macos/)

Personal Homebrew tap for my macOS applications.

## Usage

### Add the tap

```bash
brew tap giorgiobrullo/tap
```

### Install apps

```bash
brew install --cask <app-name>
```

## Available Apps

| App | Description | Install |
|-----|-------------|---------|
| [CiderTogether](https://github.com/giorgiobrullo/cider-listen-together) | Listen to music together with friends using Cider | `brew install --cask cider-together` |

## One-liner

Install any app directly without adding the tap first:

```bash
brew install --cask giorgiobrullo/tap/cider-together
```

## Updates

Apps are automatically updated when new releases are published. Run:

```bash
brew upgrade --cask
```

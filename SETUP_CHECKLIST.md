# New Mac Setup Checklist

Run `./install.sh` first, then complete these manual steps.

## Authentication

- [ ] **GitHub** - `gh auth login`
- [ ] **Claude Code** - Run `claude` and follow browser auth
- [ ] **1Password** - Sign in with account credentials
- [ ] **Slack** - Sign in to workspaces
- [ ] **Notion** - Sign in with account
- [ ] **WhatsApp** - Scan QR code from phone
- [ ] **Spotify** - Sign in with account
- [ ] **Chrome** - Sign in to sync bookmarks/extensions
- [ ] **Grammarly** - Sign in with account
- [ ] **Signal** - Link to phone
- [ ] **Zoom** - Sign in with account
- [ ] **Microsoft Teams** - Sign in with work account
- [ ] **Mullvad VPN** - Enter account number
- [ ] **Google Drive** - Sign in with Google account
- [ ] **Postman** - Sign in with account
- [ ] **Google Cloud** - `gcloud auth login`
- [ ] **Superhuman** - Sign in with email account
- [ ] **Adobe Creative Cloud** - Sign in, then install Lightroom

## App Store Apps

These must be installed from the App Store (not Homebrew):

- [ ] **Things 3** - Install from App Store (requires purchase)

## System Setup

- [ ] **Tailscale** - `sudo tailscale up --ssh`
- [ ] **SSH Key** - `ssh-keygen -t ed25519 -C "daniel.langkilde@gmail.com"`
- [ ] **Add SSH key to GitHub** - `cat ~/.ssh/id_ed25519.pub | pbcopy` then paste at github.com/settings/keys

## API Keys

- [ ] **Anthropic API Key** - Add to `~/.anthropic_api_key` (if skipped during install)

## Hardware Setup

- [ ] **Logitech Options+** - Pair mouse, camera, light
- [ ] **EVO Control** - Download from [Audient](https://audient.com/products/audio-interfaces/evo/evo-control/) for audio interface

## Verification

- [ ] Open Ghostty - confirm font and theme work
- [ ] Run `nvim` - confirm plugins install
- [ ] Run `cc` - confirm Claude Code works
- [ ] Run `z` - confirm zoxide works
- [ ] Press `Ctrl+R` - confirm fzf history works

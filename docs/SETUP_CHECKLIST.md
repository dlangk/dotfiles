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
- [ ] **NordVPN** - Sign in with account
- [ ] **Google Cloud** - `gcloud auth login`
- [ ] **Superhuman** - Sign in with email account
- [ ] **Raycast** - Sign in with Raycast account (Pro features, AI)
- [ ] **Obsidian** - Sign in with Obsidian account (if using Obsidian Sync)

## App Store Apps

These must be installed from the App Store (not Homebrew):

- [ ] **Things 3** - Task management (requires purchase)
- [ ] **Amazon Kindle** - E-reader
- [ ] **Headspace** - Meditation
- [ ] **iA Writer** - Writing app
- [ ] **X (Twitter)** - Social media

## System Setup

- [ ] **Tailscale** - `sudo tailscale up --ssh`
- [ ] **SSH Key** - `ssh-keygen -t ed25519 -C "daniel.langkilde@gmail.com"`
- [ ] **Add SSH key to GitHub** - `cat ~/.ssh/id_ed25519.pub | pbcopy` then paste at github.com/settings/keys

## API Keys

- [ ] **Anthropic API Key** - Add to `~/.anthropic_api_key` (if skipped during install)
- [ ] **Hugging Face Token** - Add to `~/.huggingface_token` (if skipped during install)
- [ ] **LinkedIn DMA Token** - Add to `~/.linkedin_dma_access_token` (if needed)

## Local Overrides (not in repo)

- [ ] **Server IPs** - Create `~/.ssh/config.local`:
  ```
  Host dl-content-host
      HostName <ip>
  Host dl-coder
      HostName <ip>
  ```
- [ ] **mosh alias** - Create `~/.zshrc.local`:
  ```bash
  alias mosh-coder="mosh daniel@<dl-coder-ip> -- tmux attach -t main"
  ```

## Hardware Setup

- [ ] **Logitech Options+** - Pair mouse, camera, light. **Then configure MX Master 3S buttons** (not synced from cloud reliably — see README.md):
    - Gesture Button → **Window Navigation**
    - Top Button → **Show/Hide Desktop**
    - Thumb Wheel → **Zoom In/Out**
- [ ] **EVO Control** - Download from [Audient](https://audient.com/products/audio-interfaces/evo/evo-control/) for audio interface
- [ ] **FUJIFILM X Acquire** - Download from [Fujifilm](https://fujifilm-x.com/global/support/download/software/) for camera tethering
- [ ] **FUJIFILM X Webcam 2** - Download from [Fujifilm](https://fujifilm-x.com/global/support/download/software/) for webcam mode

## Claude State

Restore skills and project memory so Claude Code works fully on day one:

```bash
git clone git@github.com:dlangk/claude-skills.git ~/.claude/skills
git clone git@github.com:dlangk/claude-projects.git ~/.claude/projects
```

## Dev Folders

See `docs/DEV_MAP.md` for the full folder structure and a paste-ready clone script.
The script clones all repos to the correct locations and sets up `~/.claude/skills` and `~/.claude/projects`.

Local-only dirs (no remote — must be copied manually from old machine):
- `~/dev/data-extraction/pdf2text`
- `~/dev/data-extraction/transcription`
- `~/dev/learning/machine-learning`
- `~/dev/personal-tools/claude-sessions`
- `~/dev/personal-tools/domain-check`
- `~/dev/personal-tools/gif-maker`
- `~/dev/personal-tools/hacking`
- `~/dev/personal-tools/langkilde-knowledge`
- `~/dev/personal-tools/langkilde-rolodex`
- `~/dev/personal-tools/network-sniffer`
- `~/dev/random/pareto`
- `~/kognic/board-materials`

## Verification

- [ ] Open Ghostty - confirm font and theme work
- [ ] Run `nvim` - confirm plugins install
- [ ] Run `cc` - confirm Claude Code works
- [ ] Run `z` - confirm zoxide works
- [ ] Press `Ctrl+R` - confirm fzf history works
- [ ] Run `/mac power` in Claude Code - confirm skills loaded

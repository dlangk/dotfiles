# Dotfiles

Personal development environment for macOS, optimized for Claude Code + Neovim + Git workflows.

## Quick Start (New Machine)
```bash
# 1. Clone dotfiles (will prompt to install Xcode CLT)
git clone https://github.com/dlangk/dotfiles.git ~/dotfiles

# 2. Run setup
cd ~/dotfiles
./install.sh

# 3. Complete manual steps
# Open SETUP_CHECKLIST.md or ask Claude: "guide me through the setup of my computer"
```

## What Gets Installed

### Languages & Runtimes
| Tool | Purpose |
|------|---------|
| Python 3.13 | Scripting, tools |
| Node.js | npm packages, Claude Code |
| Go | CLI tools |

### Dev Tools
| Tool | Purpose |
|------|---------|
| Claude Code | AI coding agent |
| Neovim | Terminal editor |
| VS Code | Visual editor |
| Sublime Text | Lightweight editor |
| Ghostty | Terminal emulator |
| Docker | Containers |
| tmux | Session persistence |
| gh | GitHub CLI |
| git-lfs | Large file storage |
| tree | Directory visualization |
| nginx | Web server |
| certbot | SSL certificates |
| Postman | API testing |

### Media & Documents
| Tool | Purpose |
|------|---------|
| ffmpeg | Video/audio processing |
| graphviz | Diagram generation |
| basictex | LaTeX |

### Python
| Tool | Purpose |
|------|---------|
| python@3.13 | Default Python |
| uv | Fast package/venv/tool manager (replaces pip, venv, pipx) |
| jupyterlab | Notebooks |
| ipython | Interactive shell |

**Best practices:**
- Use `uv venv` + `uv pip install` for projects (10-100x faster than pip)
- Use `uv tool install` for CLI tools (e.g., `uv tool install ruff`)
- Use `va` alias to activate `.venv` in project directories

### Shell Enhancements
| Tool | Purpose |
|------|---------|
| Starship | Minimal prompt |
| zoxide | Smart cd |
| fzf | Fuzzy finder (Ctrl+R) |
| zsh-autosuggestions | Ghost text suggestions |

### Applications
| App | Purpose |
|-----|---------|
| Claude Desktop | AI chat |
| Chrome | Browser |
| Clocker | Menu bar timezone tracker |
| Slack | Work chat |
| Notion | Notes |
| WhatsApp | Messaging |
| Signal | Messaging |
| Spotify | Music |
| Zoom | Video calls |
| Microsoft Teams | Work chat/video |
| 1Password | Password manager |
| Mullvad VPN | Privacy |
| Google Drive | Cloud storage |
| Xnapper | Screenshots |
| Stats | System monitor |
| Grammarly | Writing assistant |
| Logi Options+ | Logitech hardware |
| KeepingYouAwake | Prevent sleep |
| LM Studio | Local AI |
| Ollama | Local AI |
| Raycast | Launcher & productivity |
| Stockfish | Chess engine (CLI) |
| Superhuman | Email |
| Tella | Screen recording |
| VLC | Media player |
| Webex | Video calls |
| Adobe Creative Cloud | Lightroom |

### Manual Downloads / App Store
| App | Purpose |
|-----|---------|
| Things 3 | Task management (App Store) |
| Amazon Kindle | E-reader (App Store) |
| Headspace | Meditation (App Store) |
| iA Writer | Writing app (App Store) |
| X (Twitter) | Social media (App Store) |
| EVO Control | Audient audio interface ([Audient](https://audient.com/products/audio-interfaces/evo/evo-control/)) |
| FUJIFILM X Acquire | Camera tethering ([Fujifilm](https://fujifilm-x.com/global/support/download/software/)) |
| FUJIFILM X Webcam 2 | Webcam mode ([Fujifilm](https://fujifilm-x.com/global/support/download/software/)) |

## Files
```
~/dotfiles/
├── install.sh          # Automated setup script
├── SETUP_CHECKLIST.md  # Manual steps after install
├── README.md           # This file
├── CLAUDE.md           # Instructions for Claude
├── zshrc               → ~/.zshrc
├── gitconfig           → ~/.gitconfig
├── starship.toml       → ~/.config/starship.toml
├── ghostty/config      → ~/.config/ghostty/config
├── nvim/               → ~/.config/nvim/
├── vscode/             → ~/Library/Application Support/Code/User/
└── claude/             → ~/.claude/
```

## Key Aliases

| Alias | Command | Notes |
|-------|---------|-------|
| `cc` | `claude --dangerously-skip-permissions` | Fast mode |
| `v` | `nvim` | Quick edits |
| `c` | `code` | VS Code |
| `s` | `subl` | Lightweight edits |
| `va` | `source .venv/bin/activate` | Python venv |
| `gs` | `git status` | |
| `ta` | `tmux attach -t` | Attach session |

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+F` | Accept autosuggestion |
| `Ctrl+T` | Fuzzy file picker |

## Updating
```bash
cd ~/dotfiles
# Edit files directly (they're symlinked)
git add -A && git commit -m "Update config" && git push
```

## Updating Apps
```bash
brew upgrade        # CLI tools
brew upgrade --cask # GUI apps
```

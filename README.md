# Dotfiles

Personal development environment for macOS, optimized for Claude Code + Neovim + Git workflows.

## Quick Start (New Machine)
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone dotfiles
git clone git@github.com:dlangk/dotfiles.git ~/dotfiles

# 3. Run setup
cd ~/dotfiles
./install.sh
```

## What Gets Installed

### Core Tools
| Tool | Purpose | Install |
|------|---------|---------|
| Claude Code | AI coding agent | `npm install -g @anthropic-ai/claude-code` |
| Neovim | Terminal editor | `brew install neovim` |
| Cursor | Visual editor + AI | Download from cursor.com |
| Sublime Text | Lightweight editor | `brew install --cask sublime-text` |
| Ghostty | Terminal emulator | `brew install --cask ghostty` |

### Shell Enhancements
| Tool | Purpose | Install |
|------|---------|---------|
| Starship | Minimal prompt | `brew install starship` |
| zoxide | Smart cd | `brew install zoxide` |
| fzf | Fuzzy finder (Ctrl+R) | `brew install fzf` |
| zsh-autosuggestions | Ghost text suggestions | `brew install zsh-autosuggestions` |

### Dev Tools
| Tool | Purpose | Install |
|------|---------|---------|
| tmux | Session persistence | `brew install tmux` |
| Tailscale | Remote access from phone | `brew install tailscale` |

## Files
```
~/dotfiles/
├── README.md           # This file
├── install.sh          # Automated setup script
├── zshrc               # Shell config → ~/.zshrc
├── gitconfig           # Git config → ~/.gitconfig
├── starship.toml       # Prompt config → ~/.config/starship.toml
├── ghostty/
│   └── config          # Terminal config → ~/.config/ghostty/config
└── nvim/               # Neovim config → ~/.config/nvim/
    ├── init.lua
    └── lua/
        ├── config/     # Core settings
        └── plugins/    # Plugin specs (lazy.nvim)
```

## Manual Steps

### 1. Authenticate Claude Code
```bash
claude
# Follow browser auth flow
```

### 2. Set up Tailscale (for mobile access)
```bash
# If using Homebrew install:
sudo brew services start tailscale
sudo tailscale up --ssh

# Or install from App Store (easier)
```

### 3. Symlink Neovim Config
```bash
ln -s ~/dotfiles/nvim ~/.config/nvim
```
First launch will auto-install lazy.nvim and all plugins.

### 4. SSH Keys
```bash
# Generate new key
ssh-keygen -t ed25519 -C "daniel.langkilde@gmail.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub | pbcopy
# Paste at github.com/settings/keys
```

## Key Aliases

| Alias | Command | Notes |
|-------|---------|-------|
| `cc` | `claude --dangerously-skip-permissions` | Fast mode |
| `v` | `nvim` | Quick edits |
| `c` | `cursor` | Visual editor |
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
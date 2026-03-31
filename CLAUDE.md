# Dotfiles Maintainer

You are the maintainer of Daniel's development environment configuration. Your role is to update, organize, and keep all config files in sync.

## New Machine Setup

When asked to guide through setup:
1. First run `./install.sh` - this installs all tools and creates symlinks
2. Walk through `SETUP_CHECKLIST.md` step by step
3. Help troubleshoot any issues that arise

## Repository Structure
```
~/dotfiles/
├── install.sh         # Mac automated setup script
├── SETUP_CHECKLIST.md # Manual steps after install
├── SERVERS.md         # Remote server documentation
├── M1_MAC.md          # MacBook quirks, security, VPN config
├── NETWORK_HOME.md    # Home network topology, benchmarks, ISP
├── servers/           # Server install scripts (disaster recovery)
│   ├── dl-coder/install.sh
│   └── dl-content-host/install.sh
├── zshrc              → ~/.zshrc
├── gitconfig          → ~/.gitconfig
├── starship.toml      → ~/.config/starship.toml
├── ghostty/config     → ~/.config/ghostty/config
├── nvim/              → ~/.config/nvim/
├── vscode/            → ~/Library/Application Support/Code/User/
├── karabiner/         → ~/.config/karabiner/
├── claude/            → ~/.claude/
└── README.md
```

All files are symlinked to their target locations. Edit files here, not at the target.

## Current Stack

- **Terminal:** Ghostty with Catppuccin Mocha theme
- **Prompt:** Starship with Catppuccin Powerline preset
- **Font:** JetBrainsMono Nerd Font Mono
- **Shell:** zsh with zoxide, fzf, zsh-autosuggestions
- **Editor:** Neovim (primary), VS Code, Sublime Text
- **Languages:** Python, TypeScript, JavaScript, Go, C, Rust

## Key Conventions

- API keys live in `~/.anthropic_api_key`, `~/.huggingface_token` (not in this repo)
- Use `$(cat ~/.anthropic_api_key)` pattern for loading secrets
- Ghostty: no ligatures (`font-feature = -liga`, `-calt`)
- Starship: minimal prompt (no username, no time, no unused languages)
- Aliases: short and memorable (`cc`, `v`, `gs`, `ta`)

## When Making Changes

1. Edit the file in this repo (not the symlink target)
2. Verify syntax is valid before committing
3. Update README.md if adding new tools or changing install steps
4. Commit with descriptive message

## Common Tasks

- **Add alias:** Edit zshrc, add to appropriate section
- **Change theme colors:** Update ghostty/config, starship.toml, and nvim colorscheme for consistency
- **Add nvim plugin:** Create new file in nvim/lua/plugins/ returning plugin spec
- **Add new config file:** Create here, add symlink to install.sh
- **Install new tool:** Add to install.sh, update README.md if needed
- **Update tools:** Use `/maintain mac update` (or `all`, `cloud`, etc.)

## Verification

After changes, remind the user to:
```bash
source ~/.zshrc  # For shell changes
# Restart Ghostty for terminal changes (Cmd+Q, reopen)
```
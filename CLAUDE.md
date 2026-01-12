# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal dotfiles for macOS development environment, optimized for Claude Code + Neovim + Git workflows.

## Structure

```
zshrc              # Shell config (symlinked to ~/.zshrc)
starship.toml      # Prompt config (symlinked to ~/.config/starship.toml)
ghostty/config     # Terminal config (symlinked to ~/.config/ghostty/config)
```

## Setup

Files are symlinked to their destinations. Edits in ~/dotfiles are immediately reflected in the live config.

```bash
# After editing config files, commit directly:
git add -A && git commit -m "Update config" && git push
```

## Key Aliases Defined in zshrc

- `cc` - claude --dangerously-skip-permissions (fast mode for trusted repos)
- `v` - nvim
- `gs/ga/gc/gp/gd` - git status/add/commit/push/diff
- `va/vd/venv` - Python venv activate/deactivate/create
- `ta/tn/tl/tk` - tmux attach/new/list/kill

## Shell Features

- **zoxide**: `cd` is aliased to `z` (smart directory jumping)
- **fzf**: Ctrl+R for fuzzy history, Ctrl+T for file picker
- **Auto-venv**: Automatically activates .venv when entering directories
- **Large history**: 100k lines, shared across terminals

## Theme

Uses Catppuccin Mocha color palette across Starship prompt and Ghostty terminal.

# ~/.zshrc
# Terminal setup optimized for Claude Code, Neovim, and Git workflows
# Maintained in: https://github.com/dlangk/dotfiles

## PATH --------------------------------------------------------
# Homebrew binaries take precedence over system binaries
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
# Local binaries (uv tools, custom scripts)
export PATH="$HOME/.local/bin:$PATH"

## Go -------------------------------------------------------------
# GOPATH for Go modules and installed tools
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

## AI Model APIs -----------------------------------------------
if [[ -f ~/.anthropic_api_key ]]; then
    _api_key=$(cat ~/.anthropic_api_key)
    [[ "$_api_key" != "skipped" ]] && export ANTHROPIC_API_KEY="$_api_key"
    unset _api_key
fi

## Editor ------------------------------------------------------
# Default editor for git commits, crontab, etc.
# Claude Code also reads this for /memory and other edit commands
export EDITOR="nvim"
export VISUAL="nvim"

## History -----------------------------------------------------
# Large history is essential for long Claude Code sessions
# where you may want to recall commands from hours ago
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY          # Share history across all open terminals
setopt HIST_IGNORE_DUPS       # Don't record duplicate commands in a row
setopt HIST_IGNORE_SPACE      # Commands starting with space won't be recorded
                              # Useful for: ` export SECRET=xyz` (note leading space)
setopt HIST_REDUCE_BLANKS     # Remove unnecessary whitespace
setopt INC_APPEND_HISTORY     # Write to history immediately, not when shell exits
                              # Prevents history loss if terminal crashes

## Completion --------------------------------------------------
# Enable tab completion with case-insensitive matching
# "doc<tab>" matches "Documents"
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

## Claude Code -------------------------------------------------
# cc: Skip permission prompts for faster iteration (use in trusted repos)
# cl: Standard claude with permission prompts
# ask: Quick CLI queries via Anthropic API (go install github.com/dlangk/ask-anthropic@latest)
alias cc="claude --dangerously-skip-permissions"
alias cl="claude"
alias ask="ask-anthropic"

## Git ---------------------------------------------------------
# Short aliases for common git operations
# These match common conventions across the community
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -20"    # Compact log, last 20 commits
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gw="git worktree"             # Worktrees are great for parallel Claude Code sessions
alias gwl="git worktree list"

## Editors -----------------------------------------------------
# v:  Quick terminal edits with neovim
# c:  Open in VS Code
# s:  Open in Sublime for lightweight visual editing (copy-paste friendly)
# s.: Open current directory in Sublime
alias vi="nvim"
alias vim="nvim"
alias v="nvim"
alias c="code"
alias s="subl"
alias s.="subl ."

## tmux --------------------------------------------------------
# Essential for persistent Claude Code sessions and mobile access via Tailscale
# t:  Start tmux
# ta: Attach to named session (ta main)
# tn: Create named session (tn feature-x)
# tl: List sessions
# tk: Kill session (tk old-session)
alias t="tmux"
alias ta="tmux attach -t"
alias tn="tmux new -s"
alias tl="tmux ls"
alias tk="tmux kill-session -t"

## Python (uv) -------------------------------------------------
# uv replaces pip, venv, pipx - 10-100x faster
# venv: Create .venv in current directory
# va:   Activate the local .venv
# vd:   Deactivate current venv
alias venv="uv venv"
alias va="source .venv/bin/activate"
alias vd="deactivate"
alias pip="uv pip"
alias python="python3"

# Auto-activate: When you cd into a directory with .venv, activate it
# No more forgetting to activate before running scripts
auto_activate_venv() {
  if [[ -d .venv ]] && [[ -z "$VIRTUAL_ENV" ]]; then
    source .venv/bin/activate
  fi
}
chpwd_functions+=(auto_activate_venv)

## General -----------------------------------------------------
alias ll="ls -la"
alias la="ls -A"
alias ..="cd .."
alias ...="cd ../.."

## zoxide ------------------------------------------------------
# Smart cd that learns your habits
# "cd proj" jumps to ~/code/my-project if you go there often
# cdi: Interactive fuzzy picker for directories
eval "$(zoxide init zsh)"
alias cd="z"
alias cdi="zi"

## fzf ---------------------------------------------------------
# Fuzzy finder - transforms shell history and file navigation
# Ctrl+R: Fuzzy search through command history (game changer with 100k history)
# Ctrl+T: Fuzzy file picker
# Alt+C:  Fuzzy cd into subdirectories
source <(fzf --zsh)
export FZF_DEFAULT_OPTS='--height 40% --reverse'

## zsh-autosuggestions -----------------------------------------
# Shows ghost text suggestions based on history as you type
# Ctrl+F or right arrow: Accept suggestion
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
bindkey '^f' autosuggest-accept

## Starship prompt ---------------------------------------------
# Fast, minimal, customizable prompt
# Shows git branch, python venv, exit codes - only when relevant
# Config: ~/.config/starship.toml
eval "$(starship init zsh)"

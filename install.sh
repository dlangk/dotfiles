#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"

echo "=== Dotfiles Setup ==="

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Homebrew already installed"
fi

# Install Homebrew packages
echo "Installing Homebrew packages..."
brew install neovim starship zoxide fzf zsh-autosuggestions tmux tailscale

# Install casks
echo "Installing applications..."
brew install --cask ghostty sublime-text visual-studio-code

# Install Claude Code
if command -v npm &> /dev/null; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
else
    echo "Warning: npm not found, skipping Claude Code install"
fi

# Create config directories
mkdir -p ~/.config

# Create symlinks
echo "Creating symlinks..."
ln -sf "$DOTFILES/zshrc" ~/.zshrc
ln -sf "$DOTFILES/gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/ghostty" ~/.config/ghostty
ln -sf "$DOTFILES/nvim" ~/.config/nvim
ln -sf "$DOTFILES/claude" ~/.claude
mkdir -p "$HOME/Library/Application Support/Code/User"
ln -sf "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# Set up fzf keybindings
if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
    echo "Setting up fzf keybindings..."
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Manual steps remaining:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Authenticate Claude: claude"
echo "  3. Set up Tailscale: sudo tailscale up --ssh"
echo "  4. Generate SSH key: ssh-keygen -t ed25519 -C \"daniel.langkilde@gmail.com\""
echo ""

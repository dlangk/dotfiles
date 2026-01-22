#!/bin/bash
set -e

DOTFILES="$HOME/dotfiles"

echo "=== Dotfiles Setup ==="

# Install Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode CLT installation, then re-run this script."
    exit 1
else
    echo "Xcode Command Line Tools already installed"
fi

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
brew install python node go gh git-lfs tree ffmpeg graphviz jupyterlab ipython nginx certbot neovim starship zoxide fzf zsh-autosuggestions tmux tailscale

# Install casks (--adopt takes over existing installs for update management)
echo "Installing applications..."
brew install --cask --adopt \
    ghostty \
    sublime-text \
    visual-studio-code \
    font-jetbrains-mono-nerd-font \
    claude \
    notion \
    whatsapp \
    slack \
    google-chrome \
    spotify \
    1password \
    xnapper \
    logi-options-plus \
    stats \
    grammarly-desktop \
    postman \
    zoom \
    signal \
    mullvad-vpn \
    google-drive \
    google-cloud-sdk \
    docker \
    basictex \
    tex-live-utility \
    microsoft-teams \
    hazeover \
    lm-studio \
    ollama \
    superhuman

# Install Claude Code
echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

# Set up Anthropic API key
if [[ -f ~/.anthropic_api_key ]]; then
    echo "Anthropic API key already configured"
else
    echo ""
    read -p "Enter your Anthropic API key (or press Enter to skip): " api_key
    if [[ -z "$api_key" ]]; then
        echo "skipped" > ~/.anthropic_api_key
        echo "Skipped - you can add your key later to ~/.anthropic_api_key"
    else
        echo "$api_key" > ~/.anthropic_api_key
        echo "API key saved to ~/.anthropic_api_key"
    fi
    chmod 600 ~/.anthropic_api_key
fi

# macOS preferences
echo "Setting macOS preferences..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

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
echo "  2. Authenticate GitHub: gh auth login"
echo "  3. Authenticate Claude: claude"
echo "  4. Set up Tailscale: sudo tailscale up --ssh"
echo "  5. Generate SSH key: ssh-keygen -t ed25519 -C \"daniel.langkilde@gmail.com\""
echo ""

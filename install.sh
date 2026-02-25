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
echo "Installing CLI tools..."
brew install python@3.13 uv node go gh git-lfs tree cmake make ffmpeg graphviz imagemagick slackdump jupyterlab ipython nginx certbot neovim starship zoxide fzf zsh-autosuggestions tmux tailscale stockfish btop

# Pin python3 to 3.13 (jupyterlab may install newer Python as dependency)
ln -sf /opt/homebrew/opt/python@3.13/bin/python3.13 /opt/homebrew/bin/python3
ln -sf /opt/homebrew/opt/python@3.13/bin/pip3.13 /opt/homebrew/bin/pip3

# Install applications
echo "Installing applications..."
brew install --cask \
    ghostty \
    sublime-text \
    visual-studio-code \
    font-jetbrains-mono-nerd-font \
    claude \
    clocker \
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
    raycast \
    zoom \
    signal \
    mullvad-vpn \
    google-drive \
    google-cloud-sdk \
    docker \
    basictex \
    tex-live-utility \
    microsoft-teams \
    keepingyouawake \
    lm-studio \
    ollama \
    superhuman \
    tella \
    vlc \
    webex \
    adobe-creative-cloud \
    qlmarkdown \
    karabiner-elements \
    claude-code

# Install Python CLI tools
echo "Installing Python CLI tools..."
uv tool install ruff

# Install Rust
if command -v rustc &> /dev/null; then
    echo "Rust already installed, updating..."
    rustup update
else
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

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

# Set up Hugging Face token
if [[ -f ~/.huggingface_token ]]; then
    echo "Hugging Face token already configured"
else
    echo ""
    read -p "Enter your Hugging Face token (or press Enter to skip): " hf_token
    if [[ -z "$hf_token" ]]; then
        echo "skipped" > ~/.huggingface_token
        echo "Skipped - you can add your token later to ~/.huggingface_token"
    else
        echo "$hf_token" > ~/.huggingface_token
        echo "Token saved to ~/.huggingface_token"
    fi
    chmod 600 ~/.huggingface_token
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
mkdir -p ~/.claude
ln -sf "$DOTFILES/claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/claude/commands" ~/.claude/commands
ln -sf "$DOTFILES/claude/notify.py" ~/.claude/notify.py
mkdir -p "$HOME/Library/Application Support/Code/User"
ln -sf "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
mkdir -p ~/.config/karabiner
ln -sf "$DOTFILES/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

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

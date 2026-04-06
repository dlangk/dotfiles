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
brew install python@3.13 uv node go gh git-lfs tree cmake make ffmpeg graphviz imagemagick slackdump jupyterlab ipython mosh nginx certbot neovim starship zoxide fzf zsh-autosuggestions tmux tailscale stockfish btop just coreutils eza

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
    notion \
    whatsapp \
    slack \
    google-chrome \
    karabiner-elements \
    spotify \
    1password \
    logi-options-plus \
    grammarly-desktop \
    postman \
    raycast \
    zoom \
    signal \
    mullvad-vpn \
    little-snitch \
    nordvpn \
    google-drive \
    google-cloud-sdk \
    docker \
    basictex \
    tex-live-utility \
    microsoft-teams \
    keepingyouawake \
    lm-studio \
    superhuman \
    tella \
    vlc \
    audacity \
    reaper \
    wireshark-app \
    typefully \
    adobe-creative-cloud \
    qlmarkdown \
    claude-code \
    godot \
    wispr-flow \
    openmtp \
    obsidian

# Install manually (not available on Homebrew):
# - Amazon Kindle        — https://www.amazon.com/kindle-dbs/fd/kcp
# - Things 3             — Mac App Store
# - Headspace            — Mac App Store
# - X (Twitter)          — Mac App Store
# - Stockfish (GUI)      — Mac App Store (engine installed via brew)
# - ON1 Photo RAW        — https://www.on1.com
# - EVO (audio interface) — https://evo.audio
# - FUJIFILM X Acquire   — https://fujifilm-x.com
# - FUJIFILM X RAW STUDIO — https://fujifilm-x.com
# - FUJIFILM X Webcam 2  — https://fujifilm-x.com
# - REAPER license       — https://www.reaper.fm (app via brew, license manual)

# Install Python CLI tools
echo "Installing Python CLI tools..."
uv tool install ruff
uv tool install huggingface_hub
uv tool install aider-install && aider-install

# Install Rust
if command -v rustc &> /dev/null; then
    echo "Rust already installed, updating..."
    rustup update
else
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Install Go tools
echo "Installing Go tools..."
go install github.com/dlangk/ask-anthropic@latest

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

# macOS security hardening
echo "Hardening macOS security..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
sudo defaults write /Library/Preferences/com.apple.controlcenter.plist AirplayRecieverEnabled -bool false

# Mullvad VPN configuration
# Requires Mullvad to be installed and logged in first
if command -v mullvad &> /dev/null; then
    echo "Configuring Mullvad VPN..."
    mullvad split-tunnel set on
    mullvad split-tunnel app add /Applications/Ghostty.app
    mullvad lan set allow
    mullvad lockdown-mode set off
    mullvad dns set custom 1.1.1.1
else
    echo "Mullvad not installed or not in PATH, skipping VPN configuration"
fi

# Create config directories
mkdir -p ~/.config

# Create symlinks
echo "Creating symlinks..."
ln -sf "$DOTFILES/configs/zshrc" ~/.zshrc
ln -sf "$DOTFILES/configs/gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/configs/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/configs/ghostty" ~/.config/ghostty
ln -sf "$DOTFILES/configs/nvim" ~/.config/nvim
mkdir -p ~/.ssh
ln -sf "$DOTFILES/configs/ssh_config" ~/.ssh/config
chmod 600 ~/.ssh/config
mkdir -p ~/.claude
ln -sf "$DOTFILES/configs/claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$DOTFILES/configs/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/configs/claude/notify.py" ~/.claude/notify.py
mkdir -p "$HOME/Library/Application Support/Code/User"
ln -sf "$DOTFILES/configs/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
ln -sf "$DOTFILES/configs/karabiner" ~/.config/karabiner

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

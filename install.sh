#!/bin/bash
set -eo pipefail

DOTFILES="$HOME/dotfiles"
LOG_FILE="$DOTFILES/install.log"

# Mirror all output (stdout + stderr) to a log file so failures can be inspected
# after the run. Each invocation overwrites the previous log.
: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Report which command and line failed, and where to look for context.
trap 'rc=$?; echo ""; echo "=== install.sh FAILED ==="; echo "  exit code: $rc"; echo "  line:      $LINENO"; echo "  command:   $BASH_COMMAND"; echo "  full log:  $LOG_FILE"; exit $rc' ERR

echo "=== Dotfiles Setup ==="
echo "Logging to: $LOG_FILE"
echo "Started:    $(date)"

# Prompt for sudo once up front, then refresh the timestamp in the background
# so later sudo commands (firewall, launchctl, etc.) don't pause the script.
echo "Requesting sudo (used later for firewall/security hardening)..."
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

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
brew install nmap mtr iperf3 jq doggo corelocationcli
brew install stylua prettier clang-format  # Neovim formatter dependencies

# Pin python3 to 3.13 (jupyterlab may install newer Python as dependency)
ln -sf /opt/homebrew/opt/python@3.13/bin/python3.13 /opt/homebrew/bin/python3
ln -sf /opt/homebrew/opt/python@3.13/bin/pip3.13 /opt/homebrew/bin/pip3

# Python packages (system-wide, needed for CLI tools like gsutil which uses
# /usr/bin/python3). Requires sudo to write to /Library/Python/*/site-packages.
sudo uv pip install --system --break-system-packages crcmod

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
    raycast \
    zoom \
    signal \
    mullvad-vpn \
    little-snitch \
    nordvpn \
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
    qlmarkdown \
    godot \
    wispr-flow \
    openmtp \
    obsidian \
    mochi

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
# uv tool installs to ~/.local/bin; put it on PATH for the rest of this script
# so tools (and tools-that-call-other-tools, like aider-install) work without
# requiring the user to source their shell rc first.
export PATH="$HOME/.local/bin:$PATH"
echo "Installing Python CLI tools..."
uv tool install ruff
uv tool install black  # Neovim Python formatter
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

# Install Node.js tools
echo "Installing Node.js tools..."
npm install -g codeburn

# Install Claude Code (native installer, not Homebrew)
if [[ ! -x "$HOME/.local/bin/claude" ]]; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "Claude Code already installed"
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
# Re-enable font smoothing (disabled by default since Mojave). Text on the
# Studio Display looks thin/fuzzy without it. Requires logout to take effect.
defaults write -g CGFontRenderingFontSmoothingDisabled -bool NO

# Input source switching: Shift+Cmd+Space (next). Previous-source binding disabled.
# Cocoa modifier flags: shift=131072, ctrl=262144, cmd=1048576. Space key = 49.
# Hotkey IDs: 60 = previous input source, 61 = next input source.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 \
  "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1179648</integer></array><key>type</key><string>standard</string></dict></dict>"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
  "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"

# Free Cmd+Space for Raycast by disabling Spotlight's hotkey (ID 64).
# After install, set Raycast's global hotkey to Cmd+Space in its onboarding.
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
  "<dict><key>enabled</key><false/></dict>"

# Cycle windows of the active app with Cmd+§ (hotkey ID 27).
# Default is Cmd+` which is unreachable on Swedish ISO layouts; § is the
# key left of 1 (virtual keycode 10, character 167).
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 27 \
  "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>167</integer><integer>10</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"

# Add Swedish input source must be done manually:
#   System Settings > Keyboard > Input Sources > Edit > + > Swedish > Swedish.
# Scripting AppleEnabledInputSources is unreliable across macOS versions.

# Dock
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -int 28
defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock show-recents -bool false

# Finder
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Apply Dock and Finder changes immediately
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

# macOS security hardening
echo "Hardening macOS security..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true
sudo defaults write /Library/Preferences/com.apple.controlcenter.plist AirplayRecieverEnabled -bool false

# Tailscale daemon
# The `tailscale` brew formula is CLI-only; it ships a launchd plist but
# does not auto-start. Without this, `tailscale up` fails with
# "failed to connect to local Tailscale service".
echo "Starting Tailscale daemon..."
sudo brew services start tailscale

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
echo "Finished: $(date)"
echo "Log:      $LOG_FILE"
echo ""
echo "Manual steps remaining:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Authenticate GitHub: gh auth login"
echo "  3. Authenticate Claude: claude"
echo "  4. Set up Tailscale: sudo tailscale up --ssh"
echo "  5. Generate SSH key: ssh-keygen -t ed25519 -C \"daniel.langkilde@gmail.com\""
echo "  6. Logi Options+: after signing in, manually configure the MX Master 3S"
echo "     (button assignments do not always sync from the cloud):"
echo "       - Gesture Button (thumb) -> Window Navigation"
echo "       - Top Button             -> Show/Hide Desktop"
echo "       - Thumb Wheel            -> Zoom In/Out"
echo ""

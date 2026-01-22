#!/bin/bash
# Freshness check script - verifies machine configuration

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARNINGS++)); }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }

echo "=== Dotfiles Freshness Check ==="
echo ""

# --- Homebrew ---
echo "Checking Homebrew..."
if command -v brew &> /dev/null; then
    ok "Homebrew installed"
else
    fail "Homebrew not installed"
fi

# Check for issues
BREW_ISSUES=$(brew doctor 2>&1 | grep -c "Warning")
if [[ $BREW_ISSUES -eq 0 ]]; then
    ok "Homebrew healthy"
else
    warn "Homebrew has $BREW_ISSUES warning(s) - run 'brew doctor'"
fi

# Check for outdated
OUTDATED=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
if [[ $OUTDATED -eq 0 ]]; then
    ok "All formulae up to date"
else
    warn "$OUTDATED outdated formula(e) - run 'brew upgrade'"
fi

OUTDATED_CASKS=$(brew outdated --cask 2>/dev/null | wc -l | tr -d ' ')
if [[ $OUTDATED_CASKS -eq 0 ]]; then
    ok "All casks up to date"
else
    warn "$OUTDATED_CASKS outdated cask(s) - run 'brew upgrade --cask'"
fi

echo ""

# --- Python ---
echo "Checking Python..."
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version 2>/dev/null)
    if [[ $PY_VERSION == *"3.13"* ]]; then
        ok "Python 3.13 is default ($PY_VERSION)"
    else
        warn "Python version is $PY_VERSION (expected 3.13)"
    fi
else
    fail "python3 not found"
fi

if command -v uv &> /dev/null; then
    ok "uv installed ($(uv --version 2>/dev/null | head -1))"
else
    fail "uv not installed - run 'brew install uv'"
fi

# Check for global pip packages (should be minimal)
PIP_PACKAGES=$(pip3 list 2>/dev/null | wc -l | tr -d ' ')
if [[ $PIP_PACKAGES -lt 10 ]]; then
    ok "Global pip packages clean ($PIP_PACKAGES packages)"
else
    warn "Many global pip packages ($PIP_PACKAGES) - consider cleanup"
fi

echo ""

# --- Node ---
echo "Checking Node..."
if command -v node &> /dev/null; then
    ok "Node installed ($(node --version))"
else
    fail "Node not installed"
fi

NPM_GLOBAL=$(npm list -g --depth=0 2>/dev/null | grep -v "npm@" | grep -v "^/" | wc -l | tr -d ' ')
if [[ $NPM_GLOBAL -lt 3 ]]; then
    ok "Global npm packages clean"
else
    warn "Multiple global npm packages ($NPM_GLOBAL)"
fi

echo ""

# --- Symlinks ---
echo "Checking symlinks..."
DOTFILES="$HOME/dotfiles"

check_symlink() {
    local src="$1"
    local dst="$2"
    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
        ok "$dst → $src"
    elif [[ -L "$dst" ]]; then
        warn "$dst points to $(readlink "$dst") (expected $src)"
    elif [[ -e "$dst" ]]; then
        # Check if it's a directory with correct content symlinked inside
        if [[ -d "$dst" ]] && [[ -d "$src" ]]; then
            ok "$dst exists (contents managed)"
        else
            warn "$dst exists but not symlinked"
        fi
    else
        fail "$dst missing"
    fi
}

check_symlink "$DOTFILES/zshrc" "$HOME/.zshrc"
check_symlink "$DOTFILES/gitconfig" "$HOME/.gitconfig"
check_symlink "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
check_symlink "$DOTFILES/ghostty" "$HOME/.config/ghostty"
check_symlink "$DOTFILES/nvim" "$HOME/.config/nvim"
check_symlink "$DOTFILES/claude" "$HOME/.claude"
check_symlink "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

echo ""

# --- macOS Preferences ---
echo "Checking macOS preferences..."
KEY_REPEAT=$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null)
if [[ $KEY_REPEAT -eq 2 ]]; then
    ok "Key repeat speed set (KeyRepeat=2)"
else
    warn "Key repeat not optimized (KeyRepeat=$KEY_REPEAT, expected 2)"
fi

INITIAL_REPEAT=$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null)
if [[ $INITIAL_REPEAT -eq 15 ]]; then
    ok "Initial key repeat set (InitialKeyRepeat=15)"
else
    warn "Initial key repeat not optimized ($INITIAL_REPEAT, expected 15)"
fi

echo ""

# --- API Keys ---
echo "Checking API keys..."
if [[ -f "$HOME/.anthropic_api_key" ]]; then
    KEY_CONTENT=$(cat "$HOME/.anthropic_api_key")
    if [[ "$KEY_CONTENT" == "skipped" ]]; then
        warn "Anthropic API key skipped - add to ~/.anthropic_api_key"
    else
        ok "Anthropic API key configured"
    fi
else
    warn "Anthropic API key not found"
fi

echo ""

# --- Unwanted Apps ---
echo "Checking for unwanted apps..."
UNWANTED_APPS=(
    "/Applications/iStat Menus.app"
    "/Applications/Spark.app"
    "/Applications/Microsoft OneNote.app"
    "/Applications/OneDrive.app"
    "/Applications/Microsoft Word.app"
    "/Applications/Microsoft Excel.app"
    "/Applications/Microsoft PowerPoint.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/IntelliJ IDEA.app"
    "/Applications/PyCharm.app"
    "/Applications/WebStorm.app"
    "/Applications/CLion.app"
    "/Applications/JetBrains Gateway.app"
)

FOUND_UNWANTED=0
for app in "${UNWANTED_APPS[@]}"; do
    if [[ -d "$app" ]]; then
        warn "Unwanted app found: $app"
        ((FOUND_UNWANTED++))
    fi
done

if [[ $FOUND_UNWANTED -eq 0 ]]; then
    ok "No unwanted apps found"
fi

echo ""

# --- Services ---
echo "Checking services..."
if pgrep -x "tailscaled" > /dev/null; then
    ok "Tailscale running"
else
    warn "Tailscale not running - run 'sudo tailscale up'"
fi

echo ""

# --- Summary ---
echo "=== Summary ==="
if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${NC}"
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}$WARNINGS warning(s), no errors${NC}"
else
    echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s)${NC}"
fi

echo ""
echo "Run 'brew upgrade && brew upgrade --cask' to update all packages"

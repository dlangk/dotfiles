#!/bin/bash
# Update script - keeps everything up to date

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Dotfiles Update ==="
echo ""

# Homebrew
echo -e "${YELLOW}Updating Homebrew...${NC}"
brew update
brew upgrade
brew upgrade --cask
brew cleanup
echo -e "${GREEN}✓${NC} Homebrew updated"
echo ""

# Claude Code
echo -e "${YELLOW}Updating Claude Code...${NC}"
npm update -g @anthropic-ai/claude-code
echo -e "${GREEN}✓${NC} Claude Code updated"
echo ""

# Google Cloud SDK
if command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}Updating Google Cloud SDK...${NC}"
    gcloud components update --quiet
    echo -e "${GREEN}✓${NC} Google Cloud SDK updated"
    echo ""
fi

# Neovim plugins
if command -v nvim &> /dev/null; then
    echo -e "${YELLOW}Updating Neovim plugins...${NC}"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Neovim plugins updated"
    echo ""
fi

# Docker cleanup
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo -e "${YELLOW}Cleaning up Docker...${NC}"
    docker system prune -f
    echo -e "${GREEN}✓${NC} Docker cleaned"
    echo ""
fi

# Cache cleanup
echo -e "${YELLOW}Cleaning caches...${NC}"
npm cache clean --force 2>/dev/null || true
uv cache clean 2>/dev/null || true
echo -e "${GREEN}✓${NC} Caches cleaned"
echo ""

echo "=== Update Complete ==="

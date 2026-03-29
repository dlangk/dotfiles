#!/bin/bash
# Install script for dl-coder (Hetzner, Ubuntu 24.04)
# Remote development machine — Rust, Python, Claude Code
#
# Recreates the machine from scratch on a fresh Ubuntu 24.04 instance.
# Usage: ssh dl-coder 'bash -s' < servers/dl-coder/install.sh
set -e

echo "=== dl-coder install ==="

# --- System packages ---
echo "Installing packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y \
    build-essential curl git htop tmux mosh screen \
    python3-dev python3-pip python3-venv \
    fail2ban ufw unattended-upgrades \
    zsh strace tcpdump wget nano vim \
    net-tools sysstat lsof

# --- SSH hardening ---
echo "Hardening SSH..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload ssh

# --- Firewall ---
echo "Configuring UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 60000:61000/udp comment 'Mosh'
echo "y" | sudo ufw enable

# --- fail2ban ---
echo "Enabling fail2ban..."
sudo systemctl enable --now fail2ban

# --- Unattended upgrades ---
echo "Enabling unattended upgrades..."
sudo systemctl enable --now unattended-upgrades

# --- Passwordless sudo ---
echo "Configuring passwordless sudo..."
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null
sudo chmod 440 "/etc/sudoers.d/$USER"

# --- Zsh + Oh My Zsh ---
echo "Setting up zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || true

# --- Rust ---
echo "Installing Rust..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    rustup update
fi

# --- Node.js (for Claude Code) ---
echo "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# --- Claude Code ---
echo "Installing Claude Code..."
if ! command -v claude &> /dev/null; then
    sudo npm install -g @anthropic-ai/claude-code
fi

# --- Git config ---
echo "Configuring git..."
git config --global user.name "Daniel Langkilde"
git config --global user.email "daniel.langkilde@gmail.com"

# --- Data volume ---
# Hetzner volumes need manual attachment via console first
echo "Setting up data volume symlink..."
if [ -d /mnt/data ]; then
    mkdir -p /mnt/data/repos
    ln -sf /mnt/data/repos ~/repos
fi

echo ""
echo "=== Install complete ==="
echo ""
echo "Manual steps:"
echo "  1. Add SSH key to GitHub: ssh-keygen -t ed25519 -C 'daniel.langkilde@gmail.com'"
echo "  2. Set up Anthropic API key: echo 'YOUR_KEY' > ~/.anthropic_api_key && chmod 600 ~/.anthropic_api_key"
echo "  3. Attach Hetzner volume via console and mount at /mnt/data"
echo "  4. Restart shell: exec zsh"

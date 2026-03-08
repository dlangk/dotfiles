#!/bin/bash
# Setup script for dl-cloud-coder (Hetzner, Ubuntu 24.04)
# Remote development machine — Rust, Python, Claude Code
#
# Usage: ssh dl-cloud-coder < servers/dl-cloud-coder/setup.sh
# Or:    ssh dl-cloud-coder 'bash -s' < servers/dl-cloud-coder/setup.sh
set -e

echo "=== dl-cloud-coder setup ==="

# --- System packages ---
echo "Installing packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y \
    build-essential curl git htop tmux mosh screen \
    python3-dev python3-pip python3-venv \
    fail2ban ufw unattended-upgrades \
    zsh strace tcpdump wget nano vim

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

# --- Tailscale ---
echo "Installing Tailscale..."
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl enable --now tailscaled
# After setup, run: sudo tailscale up --ssh

# --- Data volume ---
# Hetzner volumes need manual attachment, but set up the symlink
echo "Setting up data volume symlink..."
if [ -d /mnt/data ]; then
    mkdir -p /mnt/data/repos
    ln -sf /mnt/data/repos ~/repos
fi

# --- Passwordless sudo ---
echo "Configuring passwordless sudo..."
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null
sudo chmod 440 "/etc/sudoers.d/$USER"

# --- Tailscale UFW rules (after tailscale is installed) ---
if ip link show tailscale0 &>/dev/null; then
    sudo ufw allow in on tailscale0 comment 'Tailscale'
    sudo ufw allow 41641/udp comment 'Tailscale direct'
fi

echo ""
echo "=== Base setup complete ==="
echo ""
echo "Remaining manual steps:"
echo "  1. Start Tailscale: sudo tailscale up --ssh"
echo "  2. Install Claude Code: npm install -g @anthropic-ai/claude-code"
echo "     Or use Homebrew if available"
echo "  3. Set up git:"
echo "     git config --global user.name 'Daniel Langkilde'"
echo "     git config --global user.email 'daniel.langkilde@gmail.com'"
echo "  4. Add SSH key to GitHub"
echo "  5. Restart shell: exec zsh"

#!/bin/bash
# Install script for dl-content-host (GCP e2-micro, Debian 12)
# Hosts langkilde.se — nginx reverse proxy, certbot TLS, yatzy app
#
# Recreates the machine from scratch on a fresh Debian 12 instance.
# Usage: ssh dl-content-host 'bash -s' < servers/dl-content-host/install.sh
set -e

echo "=== dl-content-host install ==="

# --- System packages ---
echo "Installing packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y \
    curl git build-essential cmake \
    fail2ban ufw unattended-upgrades \
    socat tcpdump net-tools tree \
    python3 python3-certbot-nginx \
    npm

# --- Docker ---
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io docker-compose
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
fi

# --- SSH hardening ---
echo "Hardening SSH..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
# Keep connections alive for slow networks
grep -q "^ClientAliveInterval" /etc/ssh/sshd_config || \
    echo "ClientAliveInterval 120" | sudo tee -a /etc/ssh/sshd_config > /dev/null
sudo systemctl reload sshd

# --- Firewall ---
echo "Configuring UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
echo "y" | sudo ufw enable

# --- fail2ban ---
echo "Enabling fail2ban..."
sudo systemctl enable --now fail2ban

# --- Unattended upgrades ---
echo "Enabling unattended upgrades..."
sudo systemctl enable --now unattended-upgrades

# --- Docker network ---
echo "Creating Docker network..."
sudo docker network create shared_network 2>/dev/null || true

# --- Website auto-pull cron ---
echo "Setting up git pull cron..."
(crontab -l 2>/dev/null; echo "* * * * * cd ~/langkilde && git pull > /dev/null 2>&1") | sort -u | crontab -

echo ""
echo "=== Install complete ==="
echo ""
echo "Manual steps:"
echo "  1. Clone repos:"
echo "     git clone <langkilde-repo> ~/langkilde"
echo "     git clone <nginx-config-repo> ~/nginx-langkilde-se"
echo "     git clone <yatzy-repo> ~/yatzy"
echo "  2. Start nginx + certbot: cd ~/nginx-langkilde-se && sudo docker-compose up -d"
echo "  3. Build and start yatzy: cd ~/yatzy && sudo docker-compose up -d"
echo "  4. Verify: curl https://langkilde.se"

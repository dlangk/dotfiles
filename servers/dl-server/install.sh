#!/bin/bash
# Install script for dl-server (GCP e2-small, Debian 12)
# Hosts langkilde.se — nginx reverse proxy, certbot TLS, yatzy app
#
# Recreates the machine from scratch on a fresh Debian 12 instance.
# Usage: ssh dl-server 'bash -s' < servers/dl-server/install.sh
set -e

echo "=== dl-server install ==="

# --- System packages ---
echo "Installing packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y \
    curl git build-essential cmake \
    fail2ban ufw unattended-upgrades \
    socat tcpdump net-tools tree \
    python3 python3-certbot-nginx \
    sysstat \
    npm

# --- Swap file (2GB) ---
# e2-small has only 1.9GB RAM and no swap by default; a swap file prevents
# transient memory spikes (batch jobs) from triggering the OOM killer.
echo "Configuring swap..."
if ! sudo swapon --show | grep -q /swapfile; then
    sudo fallocate -l 2G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile > /dev/null
    sudo swapon /swapfile
fi
grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
# Prefer RAM; only swap under real pressure
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
sudo sysctl -w vm.swappiness=10 > /dev/null

# --- sysstat (historical load/mem collection) ---
echo "Enabling sysstat..."
sudo sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat
sudo systemctl enable --now sysstat > /dev/null 2>&1 || true

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

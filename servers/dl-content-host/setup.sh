#!/bin/bash
# Setup script for dl-content-host (GCP e2-micro, Debian 12)
# Hosts langkilde.se — blog + yatzy app via Docker
#
# Usage: ssh dl-content-host < servers/dl-content-host/setup.sh
# Or:    ssh dl-content-host 'bash -s' < servers/dl-content-host/setup.sh
set -e

echo "=== dl-content-host setup ==="

# --- System packages ---
echo "Installing packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y \
    curl git docker.io docker-compose fail2ban ufw \
    unattended-upgrades apt-transport-https ca-certificates

# --- SSH hardening ---
echo "Hardening SSH..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl reload ssh 2>/dev/null || sudo systemctl reload sshd 2>/dev/null

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

# --- Docker ---
echo "Configuring Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER" 2>/dev/null || true

# Create shared Docker network
docker network create shared_network 2>/dev/null || true

# --- Unattended upgrades ---
echo "Enabling unattended upgrades..."
sudo systemctl enable --now unattended-upgrades

# --- Directories ---
echo "Creating directories..."
mkdir -p ~/nginx-langkilde-se ~/yatzy ~/langkilde

# --- Crontab (auto-deploy blog) ---
echo "Setting up crontab..."
(crontab -l 2>/dev/null | grep -v 'langkilde.*git pull'; echo '* * * * * cd ~/langkilde && git pull') | crontab -

echo ""
echo "=== Base setup complete ==="
echo ""
echo "Remaining manual steps:"
echo "  1. Clone repos:"
echo "     git clone <langkilde-site-repo> ~/langkilde"
echo "     git clone <nginx-config-repo> ~/nginx-langkilde-se"
echo "     git clone <yatzy-repo> ~/yatzy"
echo "  2. Copy nginx.conf, entrypoint.sh, docker-compose.yml to ~/nginx-langkilde-se/"
echo "     (or use the copies in dotfiles/servers/dl-content-host/)"
echo "  3. Copy yatzy docker-compose.yml and oracle.bin data"
echo "  4. Build and start Docker containers:"
echo "     cd ~/nginx-langkilde-se && docker compose up -d"
echo "     cd ~/yatzy && docker compose up -d"
echo "  5. Certbot will auto-provision TLS certs on first start"

# Remote Servers

## dl-content-host (Google Cloud)

| Property | Value |
|----------|-------|
| **Provider** | Google Cloud |
| **Project** | daniel-langkilde-se |
| **Zone** | europe-north1-a |
| **Machine type** | e2-micro (1 core / 2 threads, Intel Xeon @ 2.20GHz) |
| **OS** | Debian 12 (bookworm) |
| **Memory** | 1 GB |
| **Disk** | 30 GB (56% used) |
| **Public IP** | REDACTED |
| **SSH** | `ssh dl-content-host` |
| **User** | daniel.langkilde (sudo NOPASSWD) |
| **Uptime** | 677 days (as of 2026-03-08) |

### Purpose
Hosts langkilde.se — personal website and side projects.

### What's running
- **Docker** (20.10.24) with 4 containers:
  - `nginx` — reverse proxy, ports 80/443
  - `certbot` — TLS cert renewal (langkilde.se, expires 2026-05-05)
  - `yatzy-frontend` — web app
  - `yatzy-backend` — API server
- **Crontab**: `git pull` every minute in `~/langkilde/`
- **Exim4** — mail relay on localhost

### Installed tools
- Python 3.11.2, Node v18.20.4
- Docker, Nginx, Certbot
- No Go, Rust, or Java

### Home directory
```
~/daniel.langkilde/
├── langkilde/              # Website (auto-pulled via cron)
├── nginx-langkilde-se/     # Nginx config
├── yatzy/                  # Yatzy game project
├── yatzy-data/
├── yatzy-treatise/
├── daniel-daily/
└── .cloudflare/
```

### Notes
- Tailscale not installed
- Firewall is open (iptables ACCEPT all, Docker manages its own rules)
- Three user accounts exist: daniel_langkilde, langkilde, daniel.langkilde

---

## dl-cloud-coder (Hetzner Cloud)

| Property | Value |
|----------|-------|
| **Provider** | Hetzner Cloud |
| **Machine** | 4 cores / 8 threads (AMD EPYC Milan) |
| **OS** | Ubuntu 24.04.4 LTS (Noble) |
| **Memory** | 30 GB |
| **Disk** | 226 GB root (3% used) + 100 GB mounted at /mnt/data |
| **Public IP** | REDACTED |
| **IPv6** | REDACTED |
| **SSH** | `ssh dl-cloud-coder` |
| **User** | daniel (zsh + oh-my-zsh) |

### Purpose
Development / coding server — powerful machine for remote work.

### What's running
- Tailscale (connected to dlmacbook, iphone-15-pro-max)
- Minimal services (SSH, cron, systemd basics)

### Installed tools
- Python 3.12.3, Rust 1.94.0
- Claude Code (`~/.claude/` present)
- zsh with oh-my-zsh
- No Docker, Nginx, Node, Go, or Java

### Disk layout
```
/dev/sda1  226G  root (3% used)
/dev/sdb   100G  /mnt/data
```

### Home directory
```
~/daniel/
├── repos -> /mnt/data/repos   # Symlink to data volume
├── .claude/                    # Claude Code config
├── .cargo/                     # Rust toolchain
├── .rustup/
├── .oh-my-zsh/
├── .gitconfig
└── .zshrc
```

### Notes
- Tailscale IP: 100.88.112.74
- No firewall configured (ufw inactive)
- No swap
- No Docker installed
- Recently rebooted (8 min uptime as of 2026-03-08)

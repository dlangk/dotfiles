# Remote Servers

## dl-content-host (Google Cloud)

| Property | Value |
|----------|-------|
| **Provider** | Google Cloud |
| **Project** | daniel-langkilde-se |
| **Zone** | europe-north1-a |
| **Machine type** | e2-small (2 vCPU, 1/4 shared core) |
| **OS** | Debian 12 (bookworm) |
| **Memory** | 2 GB |
| **Disk** | 30 GB (38% used) |
| **SSH** | `ssh dl-content-host` |
| **User** | daniel.langkilde (sudo NOPASSWD) |

### Purpose
Hosts langkilde.se — personal website and side projects.

### What's running
- **Docker** (20.10.24) with 4 containers:
  - `nginx` — reverse proxy, ports 80/443
  - `certbot` — TLS cert renewal (langkilde.se, expires 2026-05-05)
  - `yatzy-frontend` — web app
  - `yatzy-backend` — API server
- **Crontab**: `git pull` every minute in `~/langkilde/`

### Installed tools
- Python 3.11.2, Node.js 22
- Docker, Nginx, Certbot
- No Go, Rust, or Java

### Home directory
```
~/
├── langkilde/              # Website git repo (auto-pulled via cron every minute)
├── nginx-langkilde-se/     # Nginx + certbot setup (own git repo)
│   ├── docker-compose.yml
│   ├── nginx.conf
│   ├── entrypoint.sh
│   ├── certs/              # Let's Encrypt certs (certbot-managed)
│   └── webroot/            # ACME challenge dir
├── yatzy/                  # Yatzy app (own git repo)
│   ├── docker-compose.yml
│   ├── frontend/
│   └── backend/
├── yatzy-data/             # Persistent yatzy data (oracle.bin)
├── yatzy-treatise/         # Static content served at /yatzy/
├── daniel-daily/
└── .cloudflare             # Cloudflare credentials file
```

### Notes
- Tailscale not installed
- UFW active: SSH (22), HTTP (80), HTTPS (443)
- Fail2ban active on sshd
- Three user accounts exist: daniel_langkilde, langkilde, daniel.langkilde

---

## dl-coder (Hetzner Cloud)

| Property | Value |
|----------|-------|
| **Provider** | Hetzner Cloud |
| **Machine** | 4 cores / 8 threads (AMD EPYC Milan) |
| **OS** | Ubuntu 24.04.4 LTS (Noble) |
| **Memory** | 30 GB |
| **Disk** | 226 GB root (6% used) + 100 GB mounted at /mnt/data |
| **SSH** | `ssh dl-coder` |
| **User** | daniel (zsh + oh-my-zsh) |

### Purpose
Development / coding server — powerful machine for remote work.

### What's running
- Minimal services (SSH, cron, systemd basics)
- tmux `main` session (auto-starts on boot)

### Installed tools
- Python 3.12.3, Rust 1.94.0
- Claude Code (`~/.claude/` present)
- zsh with oh-my-zsh
- Node.js 22 (installed for Claude Code)
- No Docker, Nginx, Go, or Java

### Disk layout
```
/dev/sda1  226G  root (6% used)
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
- UFW active: SSH (22), mosh (60000:61000/udp)
- Fail2ban active on sshd
- No swap
- No Docker installed
- tmux `main` session auto-starts on boot (systemd user service)

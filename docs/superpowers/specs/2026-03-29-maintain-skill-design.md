# /maintain Skill Design

## Overview

A unified skill for diagnosing and updating Daniel's three machines: Mac (local), dl-content-host (GCP), and dl-coder (Hetzner). Replaces the existing `check-server` command and `update.sh` script with a single, comprehensive tool.

## Invocation

```
/maintain <target> [action]
```

**Targets:**
- `mac` — local MacBook Pro M1 Max
- `dl-content-host` — GCP e2-micro, Debian 12
- `dl-coder` — Hetzner, Ubuntu 24.04
- `cloud` — both remote servers
- `all` — all three machines

**Actions:**
- `diagnose` — check health, report status (read-only)
- `update` — apply updates
- `both` — diagnose then update (default if action omitted)

**Examples:**
```
/maintain mac diagnose
/maintain dl-coder update
/maintain cloud both
/maintain all
```

When target is `cloud` or `all`, run machines in parallel (separate SSH sessions / concurrent commands).

---

## Diagnose

### Mac

| Check | Command | Flag if |
|---|---|---|
| macOS version | `sw_vers` | — |
| Uptime | `uptime` | — |
| SIP | `csrutil status` | Not enabled |
| Disk | `df -h /` + `diskutil info disk0 \| grep SMART` | >80% or SMART not Verified |
| Memory | `memory_pressure` | Pressure > warn |
| Battery | `system_profiler SPPowerDataType \| grep -E "Cycle Count\|Condition\|Maximum Capacity"` | Condition != Normal |
| Homebrew outdated | `brew outdated` | Any outdated |
| Homebrew health | `brew doctor 2>&1` | Warnings |
| macOS updates | `softwareupdate -l` | Any available |
| Docker Desktop | `docker info 2>/dev/null && docker system df` | Not running (info only) |
| Mullvad | `mullvad status` | — |
| Tailscale | `tailscale status` | — |
| DNS | `scutil --dns \| grep "nameserver\[0\]" \| sort -u` | — |
| Spotlight | `mdutil -s /` | Not indexing |
| Neovim plugins | `nvim --headless "+Lazy! check" +qa 2>&1` | Updates available |
| Dev tools | `python3 --version && node --version && go version && rustc --version && uv --version && gh --version && claude --version` | — |

### dl-content-host

All checks via single `ssh dl-content-host '...'` command.

| Check | Command | Flag if |
|---|---|---|
| OS / kernel | `cat /etc/debian_version && uname -r` | — |
| Uptime | `uptime -p` | — |
| Reboot needed | `[ -f /var/run/reboot-required ]` | Yes |
| Disk | `df -h / && df -i /` | >80% or inodes >80% |
| Memory / swap | `free -h` | Used >80% of total |
| APT updates | `apt list --upgradable 2>/dev/null` | Security updates pending |
| Docker containers | `sudo docker ps --format "table {{.Names}}\t{{.Status}}"` | Any unhealthy or exited |
| Docker disk | `sudo docker system df` | Reclaimable >1GB |
| Website HTTP | `curl -sI -o /dev/null -w "%{http_code}" https://langkilde.se` | Not 200/403 (403 = Cloudflare challenge, acceptable) |
| TLS cert expiry | `echo \| openssl s_client -connect langkilde.se:443 -servername langkilde.se 2>/dev/null \| openssl x509 -noout -enddate` | <14 days |
| Certbot | `sudo certbot certificates 2>/dev/null \| grep -E "Domains\|Expiry"` | Cert expiring soon |
| UFW | `sudo ufw status` | Not active |
| Fail2ban | `sudo fail2ban-client status sshd` | Not running |
| SSH hardening | `grep -E "^PermitRootLogin\|^PasswordAuthentication" /etc/ssh/sshd_config` | Root login or password auth enabled |
| Unattended-upgrades | `systemctl status unattended-upgrades --no-pager \| head -5` + last 3 log lines | Not active |
| NTP | `timedatectl status \| grep "synchronized"` | Not synced |
| DNS resolution | `dig +short google.com` | Empty |
| Systemd | `systemctl --failed --no-pager` | Any failed units |
| Journal errors (24h) | `sudo journalctl -p err --since "24 hours ago" --no-pager -q \| tail -20` | Non-SSH errors present |

### dl-coder

All checks via single `ssh dl-coder '...'` command.

| Check | Command | Flag if |
|---|---|---|
| OS / kernel | `lsb_release -ds && uname -r` | — |
| Uptime | `uptime -p` | — |
| Reboot needed | `[ -f /var/run/reboot-required ]` | Yes |
| Disk (root) | `df -h /` | >80% |
| Disk (data) | `df -h /mnt/data` | >80% |
| Inodes | `df -i / /mnt/data` | >80% |
| Memory / swap | `free -h` | Used >80% of total |
| Load average | `cat /proc/loadavg` | >4.0 (matching core count) |
| APT updates | `apt list --upgradable 2>/dev/null` | Security updates pending |
| Dev tools | `python3 --version && rustc --version && claude --version 2>/dev/null` | — |
| Rust updates | `rustup check` | Updates available |
| Tmux sessions | `tmux list-sessions 2>/dev/null` | No `main` session |
| UFW | `sudo ufw status` | Not active |
| Fail2ban | `sudo fail2ban-client status sshd` | Not running |
| SSH hardening | `grep -E "^PermitRootLogin\|^PasswordAuthentication" /etc/ssh/sshd_config` | Root login or password auth enabled |
| Unattended-upgrades | `systemctl status unattended-upgrades --no-pager \| head -5` + last 3 log lines | Not active |
| NTP | `timedatectl status \| grep "synchronized"` | Not synced |
| DNS resolution | `dig +short google.com` | Empty |
| Systemd | `systemctl --failed --no-pager` | Any failed units |
| Journal errors (24h) | `sudo journalctl -p err --since "24 hours ago" --no-pager -q \| tail -20` | Non-SSH errors present |

---

## Update

### Mac

Run locally, sequentially:

| Step | Command | Notes |
|---|---|---|
| Homebrew | `brew update && brew upgrade && brew upgrade --cask && brew cleanup` | |
| Claude Code | `npm update -g @anthropic-ai/claude-code` | |
| Rust | `rustup update` | |
| Python CLI tools | `uv tool upgrade --all` | Covers ruff and any future uv tools |
| Google Cloud SDK | `gcloud components update --quiet` | Skip if not installed |
| Neovim plugins | `nvim --headless "+Lazy! sync" +qa 2>/dev/null` | |
| TeX | `tlmgr update --self --all 2>/dev/null` | Skip if not installed |
| Docker cleanup | `docker system prune -f` | Skip if not running |
| Cache cleanup | `npm cache clean --force && uv cache clean` | |
| macOS updates | `softwareupdate -l` | **Report only, never auto-install** |

### dl-content-host

Single SSH session:

| Step | Command | Notes |
|---|---|---|
| APT | `sudo apt update && sudo apt upgrade -y` | |
| APT cleanup | `sudo apt autoremove -y && sudo apt clean` | |
| Docker images | `cd ~/langkilde && sudo docker compose pull` | Pull latest images |
| Docker recreate | `sudo docker compose up -d` | Recreate if images changed |
| Docker cleanup | `sudo docker system prune -f` | |
| Journald vacuum | `sudo journalctl --vacuum-time=7d` | |
| Reboot check | `[ -f /var/run/reboot-required ] && echo "REBOOT NEEDED"` | **Report only, never auto-reboot** |

### dl-coder

Single SSH session:

| Step | Command | Notes |
|---|---|---|
| APT | `sudo apt update && sudo apt upgrade -y` | |
| APT cleanup | `sudo apt autoremove -y && sudo apt clean` | |
| Rust | `rustup update` | Run as daniel, not sudo |
| Claude Code | `npm update -g @anthropic-ai/claude-code` | If npm available |
| Journald vacuum | `sudo journalctl --vacuum-time=7d` | |
| Reboot check | `[ -f /var/run/reboot-required ] && echo "REBOOT NEEDED"` | **Report only, never auto-reboot** |

---

## Output Format

### Diagnose output

Per-machine status table:

```
## Mac — 2026-03-29 21:45 CET

| Check              | Status                    |
|--------------------|---------------------------|
| macOS              | 15.4 (Sequoia)            |
| Uptime             | 2 days                    |
| SIP                | OK                        |
| Disk               | OK (45%)                  |
| SMART              | Verified                  |
| Battery            | OK (92%, Normal, 187 cycles) |
| Memory             | OK (no pressure)          |
| Homebrew           | 3 outdated                |
| macOS updates      | 1 available               |
| Docker             | Running, 2.1GB reclaimable |
| Mullvad            | Connected (se-got)        |
| Dev tools          | python 3.13, node 22, ... |
```

Flag items use bold: **WARN (85%)**, **REBOOT NEEDED**, **CERT EXPIRES IN 5 DAYS**.

### Update output

Per-machine summary of what changed:

```
## dl-coder — Update Complete

- APT: 12 packages upgraded
- Rust: 1.94.0 -> 1.95.0
- Claude Code: already latest
- Journald: freed 450MB
- Reboot: not needed
```

### Combined (both) output

Diagnose table first, then update summary, per machine.

---

## Safety Rules

1. **Never auto-install macOS updates** — report only, user decides
2. **Never auto-reboot servers** — report if needed, user decides
3. **Never run destructive commands** without explicit confirmation (e.g., `docker system prune` is acceptable, `rm -rf` is not)
4. **Diagnose is always read-only** — no side effects
5. **Update asks before proceeding** if a reboot will be required after

---

## Server Install Scripts

For disaster recovery — recreate a server from scratch:

- `servers/dl-coder/install.sh` — Ubuntu 24.04: packages, SSH hardening, UFW, fail2ban, unattended-upgrades, zsh, Rust, Node.js, Claude Code, git config, data volume
- `servers/dl-content-host/install.sh` — Debian 12: packages, Docker, SSH hardening, UFW, fail2ban, unattended-upgrades, docker network, cron git-pull

Usage:
```bash
ssh dl-coder 'bash -s' < ~/dotfiles/servers/dl-coder/install.sh
ssh dl-content-host 'bash -s' < ~/dotfiles/servers/dl-content-host/install.sh
```

---

## Replaces

- `~/dotfiles/update.sh` — deleted
- `~/dotfiles/claude/commands/check-server.md` — deleted
- `~/dotfiles/servers/dl-coder/setup.sh` — replaced by `install.sh`

---

## File Locations

- Skill: `~/.claude/skills/maintain/SKILL.md`
- Server install scripts: `~/dotfiles/servers/<machine>/install.sh`
- Design spec: `~/dotfiles/docs/superpowers/specs/2026-03-29-maintain-skill-design.md`

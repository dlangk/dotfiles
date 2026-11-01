---
name: cloud
description: Status and updates for Daniel's remote server (dl-server on GCP hosting langkilde.se). Verbs:`status` (default — read-only health check), `update` (apt, docker compose pull). Triggers on cloud status, server health, dl-server, server update, upgrade server.
---

# /cloud

Daniel's remote server (`dl-server`) — GCP e2-small, Debian 12, hosts langkilde.se (nginx + yatzy + certbot).

## Invocation

```
/cloud [verb] [--flag...]
```

**Verbs** (default: `status`):

| Verb | Side effects |
|---|---|
| `status` | none |
| `update` | apt upgrade, docker pull |

See `~/.claude/skills/CONVENTIONS.md` for universal flags.

## Safety rules

1. **Never auto-reboot** — report `REBOOT NEEDED` and ask the user.

---

## `status`

Read-only. Single SSH session: `ssh dl-server '...'`.

```bash
cat /etc/debian_version && uname -r
uptime -p
[ -f /var/run/reboot-required ] && echo "REBOOT NEEDED" || echo "No reboot needed"

df -h / && df -i /
free -h

apt list --upgradable 2>/dev/null | tail -n +2

sudo docker ps --format "table {{.Names}}\t{{.Status}}"
sudo docker system df

# Website — check nginx container directly (Cloudflare blocks GCP IP)
curl -sI -o /dev/null -w "HTTP %{http_code}" http://localhost:80
echo | openssl s_client -connect langkilde.se:443 -servername langkilde.se 2>/dev/null | openssl x509 -noout -enddate

sudo certbot certificates 2>/dev/null | grep -E "Domains|Expiry"

sudo ufw status
sudo fail2ban-client status sshd
grep -E "^PermitRootLogin|^PasswordAuthentication" /etc/ssh/sshd_config

systemctl status unattended-upgrades --no-pager | head -5
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null | tail -3
timedatectl status | grep "synchronized"
dig +short google.com

systemctl --failed --no-pager
sudo journalctl -p err --since "24 hours ago" --no-pager -q | tail -20
```

**Flag if:**
- Disk >80% or inodes >80%
- Memory >80% used (only 1GB total — runs tight)
- Reboot needed
- Any Docker container unhealthy or exited
- TLS cert <14 days to expiry
- UFW not active / Fail2ban not running
- Root login or password auth enabled
- NTP not synced / DNS resolution fails
- Any failed systemd units
- Non-SSH journal errors (SSH scanner noise is normal)

---

## `update`

Mutates. Single SSH session. Reboots are reported only — never executed.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y && sudo apt clean

# Docker — pull latest images and recreate (v2 plugin: `docker compose`, not `docker-compose`)
cd ~/nginx-langkilde-se && sudo docker compose pull && sudo docker compose up -d
cd ~/yatzy && sudo docker compose pull && sudo docker compose up -d

sudo docker system prune -f

sudo journalctl --vacuum-time=7d

[ -f /var/run/reboot-required ] && echo "REBOOT NEEDED — ask user"
```

---

## Output

Table following the standard skill output contract:

```
Cloud status: dl-server healthy

## dl-server
| Check | Status |
|---|---|
| OS | Debian 12.13, kernel 6.1.0-47 |
| Reboot | No reboot needed |
| Disk | OK (36%) |
| ...

1 host checked, 0 need reboot, 0 errors
```

`--quiet` collapses to summary line + count.

---

## Server install scripts

If the host is lost:

```bash
ssh dl-server 'bash -s' < ~/dotfiles/servers/dl-server/install.sh
```

Install scripts live in `~/dotfiles/servers/<host>/` and are tracked in git.

Check and maintain machines. Argument: machine name (`mac`, `dl-content-host`, `dl-coder`, or `all`). If no argument given, check all three.

Reference `~/dotfiles/SERVERS.md` for remote server details.

## Mac (local machine)

Run local checks (no SSH needed):

- Disk usage (`df -h /`)
- Memory pressure (`memory_pressure`)
- Homebrew: `brew outdated`, `brew doctor`
- Docker: running containers, disk usage
- Pending macOS updates (`softwareupdate -l`)
- Uptime

Auto-fix: `brew cleanup`, `docker system prune -f` (if Docker running).

Present results in the same status table format (skip server-only checks like kernel, UFW, fail2ban, unattended-upgrades).

## Remote servers: Phase 1 — Diagnose

SSH into the server and run a comprehensive health check. Collect all output in a single SSH command:

- OS and kernel version (check if running kernel matches installed kernel)
- Uptime
- Disk usage (`df -h`) and inode usage (`df -i`)
- Memory usage (`free -h`)
- Swap status
- Pending apt updates (`apt list --upgradable 2>/dev/null`)
- Unattended-upgrades status
- Failed systemd units (`systemctl --failed`)
- Journald disk usage (`journalctl --disk-usage`)
- Docker: version, running containers, dangling images (`docker images -f dangling=true -q | wc -l`), disk usage (`docker system df`)
- TLS certificates: expiry dates (`sudo certbot certificates 2>/dev/null`)
- SSH config: password auth, root login (`grep -E 'PasswordAuth|PermitRoot' /etc/ssh/sshd_config`)
- Firewall status: `sudo ufw status` or `sudo iptables -L -n | head -20`
- fail2ban status: `systemctl status fail2ban 2>/dev/null`
- Open ports: `ss -tlnp`
- Tailscale status: `tailscale status 2>/dev/null`

## Phase 2: Auto-fix (safe, no downtime)

Run these fixes without asking:

1. **Prune Docker** — `docker image prune -f` and `docker container prune -f`
2. **Vacuum journald** — `sudo journalctl --vacuum-size=500M`
3. **Clean apt cache** — `sudo apt-get clean`
4. **Disable broken services** — if system nginx is failed and Docker nginx is running, run `sudo systemctl disable --now nginx`

Report what was fixed.

## Phase 3: Report & recommend

Present a status table, then list any issues that need confirmation:

### Status table format
```
Server: <name>
Checked: <timestamp>

| Check              | Status |
|--------------------|--------|
| Kernel             | OK / STALE (running X, installed Y) |
| Disk               | OK (X% used) / WARN (>80%) |
| Memory             | OK / WARN |
| Docker             | OK (N containers) / WARN |
| TLS cert           | OK (expires DATE) / WARN (<30 days) |
| SSH hardening      | OK / WARN (details) |
| Firewall           | OK / NOT CONFIGURED |
| fail2ban           | OK / NOT INSTALLED |
| Unattended upgrades| OK / NOT CONFIGURED |
| Systemd            | OK / FAILED (list) |
| Tailscale          | OK / NOT INSTALLED |
```

### Ask before acting on:
- **Kernel mismatch** — "Server needs a reboot to load kernel X. Reboot now?"
- **UFW not enabled** — "Enable UFW with rules: allow 22/tcp, 80/tcp, 443/tcp?"
- **fail2ban missing** — "Install fail2ban for SSH brute-force protection?"
- **TLS cert expiring <30 days** — "Force certbot renewal?"
- **Docker version outdated** — "Current version X is EOL. Upgrade?"
- **Multiple unused user accounts** — "Found accounts: X. Remove any?"
- **Pending security updates** — "Apply N pending updates?"

Only ask about issues that actually exist. Don't list clean items as questions.

## When running for `all`

Run all three checks in parallel (mac locally, both servers via SSH). Then present combined results and per-machine actions.

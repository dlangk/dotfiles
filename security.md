# Security Configuration

## Philosophy

Set once, works everywhere. No toggling between home and untrusted networks.
All settings are permanent — they don't interfere with normal usage at home.

## macOS Hardening (automated via install.sh)

| Setting | Value | Why |
|---------|-------|-----|
| Firewall | On | Blocks unsolicited inbound connections. NAS/internet access is outbound — unaffected. |
| Stealth mode | On | Mac doesn't respond to ping. No downside. |
| File Sharing (SMB) | Off | Nothing needs to connect *to* the Mac. NAS access is outbound. |
| AirPlay receiver | Off | Only cast *from* Mac, never *to* it. Closes ports 5000 and 7000. |

### Verify current state

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
sudo defaults read /Library/Preferences/com.apple.controlcenter.plist AirplayRecieverEnabled
# Expected: "Firewall is enabled", "Firewall stealth mode is on", "0"
```

## Mullvad VPN (automated via install.sh)

Use on all untrusted networks: hotels, trains, cafes. Leave off at home (full gigabit speed).

### Recommended settings

| Setting | Value | Why |
|---------|-------|-----|
| Kill switch | On | Blocks traffic if VPN drops unexpectedly |
| Lockdown mode | Off | Too aggressive — blocks internet when Mullvad is intentionally off |
| Local network sharing | On | Required to reach NAS, printers, local dev servers |
| DNS content blocking | Ads + trackers + malware | Free privacy/security improvement |
| DAITA | Off | For high-threat users. Adds bandwidth overhead. |
| Multihop | Off | Doubles latency. Overkill for hotel/train threat model. |
| Quantum resistant tunneling | On | Negligible overhead, protects against future quantum decryption |
| Split tunneling | Ghostty excluded | Routes all terminal traffic outside VPN — stable across Claude Code updates |

### Split tunneling rationale

Ghostty (not the Claude binary) is excluded because:
- Claude Code's binary path changes on every update, breaking version-specific entries
- Ghostty path is permanent (`/Applications/Ghostty.app`)
- API tools (Claude Code, gh CLI) work from terminal and get blocked by VPN exit node IP blacklists
- All terminal traffic is TLS-encrypted anyway — VPN adds nothing on top

### Server selection

Always use Sweden → **"Fastest server"** (auto). Mullvad pings all Swedish servers and picks best.
- `se-got` — Gothenburg (closest to home, lowest latency)
- `se-sto` — Stockholm (fallback)

### CLI configuration

```bash
mullvad split-tunnel set on
mullvad split-tunnel app add /Applications/Ghostty.app
mullvad lan set allow
mullvad lockdown-mode set off
mullvad connect
mullvad status
```

## Threat model

### Untrusted networks (hotel, train, cafe)
- **Client isolation may be OFF** (confirmed on SJ train) — other devices visible at layer 2
- **ARP spoofing** is theoretically possible — Mullvad's WireGuard tunnel eliminates this
- **DNS hijacking** — Mullvad routes DNS through encrypted tunnel
- **HTTPS traffic** — already encrypted, VPN adds defense-in-depth

### What Mullvad does NOT protect against
- Compromised HTTPS certificates (watch for browser warnings — never click through on untrusted networks)
- Apps using plain HTTP internally
- Traffic from apps in split tunneling (Ghostty/terminal)

## Network observations

### Scandic Haymarket (hotel) — 2026-03-27
- Subnet: 10.93.0.0/19 (8k addresses)
- Gateway: 10.93.0.1 — Apache + Java/Struts (`/tips/welcome.action`)
- Vendor: **HPE Aruba Networks** (confirmed via copyright 2022 in page source)
- Infrastructure: `guestwifi.scandichotels.com` — Scandic corporate-managed, not hotel-level
- Client isolation: **ON** — no guest devices visible
- TLS: GoDaddy cert, valid Apr 2025–Apr 2026
- Risk: Aruba controller reachable from guest subnet; `/api/v1` returns 403; Apache version undisclosed

### SJ X2000 train — 2026-03-27
- Subnet: 10.101.0.0/21 (2k addresses)
- Gateway: 10.101.0.1 — `CN=ombord.info, O=Icomera AB`
- Vendor: **Icomera AB** (Gothenburg) — specialist train/bus WiFi, cellular bonding backhaul
- DHCP lease: 20 min (high-turnover transit network)
- Client isolation: **OFF** — 20 passenger devices visible in ARP table
- Other devices: all using MAC randomization, all ports closed, no file sharing found
- Infrastructure device: 10.101.4.1 (`00:00:5b:03:b3:09`) — non-randomized MAC, likely Icomera onboard unit

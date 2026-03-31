# MacBook Pro 14" M1 Max

Machine-specific quirks, security config, and notes for Daniel's primary machine.

- **Model:** MacBook Pro 14" (2021), M1 Max, 64GB RAM, 2TB SSD
- **macOS:** Sequoia
- **Terminal:** Ghostty
- **Shell:** zsh

---

## Known Quirks

### Little Snitch
- Blocks traffic on **new/unknown networks** by default
- iPhone Wi-Fi hotspot triggers this — must approve the network on first connect
- Once approved, the hotspot network is remembered
- CLI: `/Applications/Little Snitch.app/Contents/Components/littlesnitch` (profiles and prefs only, no rule management)

### DNS
- macOS DNS is **per-interface**, no global setting
- All interfaces set to Cloudflare primary (`1.1.1.1`) + Bahnhof fallback (`213.80.101.3`)
- Reason: Bahnhof DNS has DNSSEC validation issues with `.ai` TLD (SERVFAIL on claude.ai, 2026-03-31)
- When EE5301 router arrives, set DNS there instead and revert interfaces to DHCP

### Battery
- **841 cycles, 77% max capacity, Service Recommended** (as of 2026-03-29)
- Schedule battery replacement

### Network Interfaces
| Interface | Device | Notes |
|-----------|--------|-------|
| en0 | Wi-Fi | Also used for iPhone hotspot |
| en11 | Kalea 10G USB-C (TB4) | Direct to right TB4 port, currently negotiates 1G |
| en10 | Belkin INC006 dock ethernet | USB GbE NIC inside dock, unused for internet |
| en22 | USB 2.5G adapter | Previous adapter, replaced by Kalea |

---

## Security

### Philosophy

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
| DNS | Custom: 1.1.1.1 | Mullvad's default DNS breaks split-tunneled apps (Claude Code, gh CLI). 1.1.1.1 resolves correctly for all processes. |
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
mullvad dns set custom 1.1.1.1
mullvad connect
mullvad status
```

## Threat model

### Untrusted networks (hotel, train, cafe)
- **Client isolation may be OFF** — other devices may be visible at layer 2
- **ARP spoofing** is theoretically possible — Mullvad's WireGuard tunnel eliminates this
- **DNS hijacking** — Mullvad routes DNS through encrypted tunnel
- **HTTPS traffic** — already encrypted, VPN adds defense-in-depth

### What Mullvad does NOT protect against
- Compromised HTTPS certificates (watch for browser warnings — never click through on untrusted networks)
- Apps using plain HTTP internally
- Traffic from apps in split tunneling (Ghostty/terminal)

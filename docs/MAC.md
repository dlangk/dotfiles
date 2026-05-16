# MacBook Pro 14" M5 Max

Machine-specific quirks, security config, and notes for Daniel's primary machine.

- **Model:** MacBook Pro 14" (2026), M5 Max, 128GB RAM, 2TB SSD
- **Model identifier:** Mac17,7
- **Chip:** Apple M5 Max — 18 cores (6 Super + 12 Performance)
- **Serial:** D5JXNP76DF
- **macOS:** 26.5 (build 25F71)
- **Terminal:** Ghostty
- **Shell:** zsh

Replaced the previous MacBook Pro 14" M1 Max (2021, 64GB) in May 2026.

---

## Mobile Devices

| Device | Model | OS |
|--------|-------|----|
| DL iPhone | iPhone 15 Pro Max | iOS 26.3.1 |
| DL iPad Pro | iPad Pro 11" 4th gen (M2, 2022), 256GB, Wi-Fi | iPadOS 26.2.1 |

---

## Peripherals

| Peripheral | Model | Notes |
|------------|-------|-------|
| Keyboard | Apple Magic Keyboard (wireless) | Form factor matches laptop keyboard exactly — critical for typing speed. Mechanical keyboards tested and rejected for this reason. |
| Mouse | Logitech MX 3S | |

---

## Cables

| Cable | Qty | Notes |
|-------|-----|-------|
| Apple 240W USB-C Charge Cable (2m) | 2 | White, braided, USB 2.0 data |
| Apple 60W USB-C Charge Cable (1m) | 2 | White, braided, USB 2.0 data |
| Apple MagSafe 3 Cable | 1 | |
| Apple Thunderbolt 4 Pro Cable (3m) | 1 | Black braided, 40 Gbps, 100W — Studio Display to Belkin dock |
| Apple Thunderbolt 4 Pro Cable (1.8m) | 1 | Black braided, 40 Gbps, 100W — Mac to Belkin dock |

---

## Known Quirks

### Little Snitch
- Blocks traffic on **new/unknown networks** by default
- iPhone Wi-Fi hotspot triggers this — must approve the network on first connect
- Once approved, the hotspot network is remembered
- CLI: `/Applications/Little Snitch.app/Contents/Components/littlesnitch` (profiles and prefs only, no rule management)

### DNS
- macOS DNS is **per-interface**, no global setting
- All interfaces set to DHCP (router-supplied at home)
- Bahnhof had DNSSEC issues with `.ai` TLD (2026-03-31), resolved 2026-04-05 — reverted to DHCP

### Battery
- **4 cycles, 100% max capacity** (as of 2026-05-16, brand new machine)

### Network Interfaces
| Interface | Device | Notes |
|-----------|--------|-------|
| en0 | Wi-Fi | Also used for iPhone hotspot |
| en8 | Kalea 10G USB-C (TB4 via dock) | Negotiates 10Gbase-T full-duplex on M5 (was 1G on M1) |
| en7 | Belkin dock ethernet | USB GbE NIC inside dock, unused for internet |

Interface numbering differs from the M1 machine — `en8` is the 10G adapter here (was `en11` on M1). Update scripts that hardcode interface names.

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

## VPN

### Mullvad (primary, automated via install.sh)

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

### NordVPN (backup for China travel)

Mullvad is blocked in China. NordVPN has obfuscated servers that work behind the Great Firewall.
Keep both installed — use Mullvad everywhere except China, use NordVPN in China.

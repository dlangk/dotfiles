---
name: mac
description: Status, audit, update, and power inspection for Daniel's MacBook Pro M5 Max. Verbs:`status` (default — fast health overview), `audit` (deep security/integrity scan), `update` (brew/rust/node/claude/etc.), `power` (battery, charger, energy draw). Triggers on update, upgrade, maintain, check my mac, health check, mac status, battery, power draw, energy, security audit, malware check.
---

# /mac

Daniel's MacBook Pro 14" M5 Max (128GB, macOS 26.5). Status, audit, update, power.

## Invocation

```
/mac [verb] [--flag...]
```

**Verbs** (default: `status`):

| Verb | Side effects | Roughly takes |
|---|---|---|
| `status` | none | 5–10s |
| `audit`  | none | 1–3 min (12 phases) |
| `update` | mutates (brew, rustup, uv, npm, etc.) | 2–10 min |
| `power`  | none | 3s |

See `~/.claude/skills/CONVENTIONS.md` for universal flags (`--dry-run`, `--yes`, `--verbose`, `--quiet`).

---

## `status`

Fast health check — read-only. Default verb when none given.

```bash
# System
sw_vers
uptime
csrutil status

# Disk + SMART
df -h /
diskutil info disk0 | grep -E "SMART|Media Name"

# Memory
memory_pressure | head -5

# Battery
system_profiler SPPowerDataType | grep -E "Cycle Count|Condition|Maximum Capacity"

# Homebrew
brew outdated
brew doctor 2>&1 | head -10

# macOS updates
softwareupdate -l

# Docker
docker info 2>/dev/null && docker system df || echo "Docker not running"

# Network
mullvad status 2>/dev/null || echo "Mullvad not running"
tailscale status 2>/dev/null || echo "Tailscale not running"
scutil --dns | grep "nameserver\[0\]" | sort -u

# Spotlight
mdutil -s /

# Neovim plugins
nvim --headless "+Lazy! check" +qa 2>&1 || true

# Dev tool versions
python3 --version
node --version
go version
rustc --version
uv --version
gh --version
claude --version 2>/dev/null
```

**Flag if:**
- Disk >80%
- SMART not Verified
- Battery condition != Normal
- Memory pressure > warn
- SIP not enabled
- Any homebrew outdated packages
- Any macOS updates available
- Spotlight not indexing

---

## `audit`

Deep security and integrity scan. Read-only but slow. 12 phases — run all or narrow with positional args (`/mac audit network persistence`).

### Phase 1: Suspicious Processes & CPU

```bash
ps aux -r | head -30
ps aux | grep -iE "keylog|record|monitor|inject|hook|payload|miner|crypto" | grep -v grep
log show --predicate 'subsystem == "com.apple.xpc"' --last 1h 2>/dev/null | tail -20
```

**Known benign high-CPU:** `contactsd`, `mds_stores`/`mdworker`, `tailscaled`, `avconferenced`, `com.apple.WebKit.WebContent`.
**Suspicious if persistent:** unknown process with network activity, no code signature, running as root.

### Phase 2: Persistence Mechanisms

```bash
ls -la ~/Library/LaunchAgents/
ls -la /Library/LaunchAgents/
ls -la /Library/LaunchDaemons/
sfltool dumpBackgroundTaskManagement 2>/dev/null | grep -A 2 "identifier"
crontab -l 2>/dev/null
sudo crontab -l 2>/dev/null
defaults read com.apple.loginwindow LoginHook 2>/dev/null
defaults read com.apple.loginwindow LogoutHook 2>/dev/null
```

**Baseline:** only Apple, Homebrew, and known apps (Mullvad, NordVPN, Little Snitch, Tailscale) in those dirs. No crontab expected.
- **NordVPN is wanted** (`com.nordvpn.macos.helper` daemon/privileged helper). Daniel runs both Mullvad and NordVPN by choice — see `~/dotfiles/docs/MAC.md`.
**Red flags:** entries pointing to `/tmp`, `/var/folders`, or home directory scripts.

### Phase 3: Network Activity

```bash
lsof -i -P -n | grep -E "LISTEN|ESTABLISHED" | sort
netstat -an | grep LISTEN
scutil --dns | grep "nameserver\[0\]" | sort -u
cat /etc/hosts
scutil --proxy
lsof -i -P -n | grep -v "^COMMAND" | grep -vE "chrome|firefox|safari|slack|spotify|zoom|teams|notion|code|nvim|node|python|ruby" | head -30
```

**Expected listeners:** `rapportd`, `ControlCenter`, `tailscaled` (100.x.x.x), Little Snitch, `mDNSResponder`.
**Note on Tailscale:** UDP STUN to 3478 + DERP relay servers globally is normal.
**Note on NordVPN (wanted):** `com.nordvpn.macos.Shield.systemextension` (Threat Protection content filter) and `com.nordvpn.macos.helper` running is expected — not a finding.

### Phase 4: TCC Permissions (Privacy Database)

```bash
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client, auth_value FROM access WHERE auth_value=2 ORDER BY service;" 2>/dev/null
```

`auth_value`: 0=denied, 2=allowed.

| Service | Risk | Expected apps |
|---|---|---|
| `kTCCServiceAccessibility` | Keylogger, UI control | Raycast, BTT, Little Snitch, Logi Options+ |
| `kTCCServiceInputMonitoring` | Keylogger | Raycast, keyboard apps |
| `kTCCServiceScreenCapture` | Screen recording | Claude, Zoom, Slack, Tella |
| `kTCCServiceCamera` | Webcam | Zoom, Slack, Teams, FaceTime |
| `kTCCServiceMicrophone` | Audio | Zoom, Slack, Teams, Whispr Flow, Reaper |
| `kTCCServiceSystemPolicyAllFiles` | Full disk access | Backup apps, terminal |

Revoke: `tccutil reset <ServiceName> <BundleID>`.

### Phase 5: System Integrity

```bash
csrutil status               # expect: enabled
profiles status -type enrollment 2>/dev/null || system_profiler SPConfigurationProfileDataType 2>/dev/null | head -20
ls /Users/                   # expect: daniel + Shared only
sudo cat /etc/sudoers 2>/dev/null | grep -v "^#\|^$"
```

### Phase 6: Certificate Store (MITM Detection)

```bash
security find-certificate -a /Library/Keychains/System.keychain | grep "labl" | sort
security dump-trust-settings -d 2>/dev/null | grep -A 3 "SubjectName"
```

**Expected (wanted):** `NordVPN Threat Protection` — a self-issued root CA that NordVPN uses to TLS-inspect traffic for its Threat Protection feature. Daniel runs NordVPN by choice, so this cert is opted-in, not a compromise. See `~/dotfiles/docs/MAC.md`.
**Red flag:** *other* corporate/ISP certs that could enable HTTPS inspection (anything not Apple and not the NordVPN cert above).

### Phase 7: Browser Security (Chrome)

```bash
ls ~/Library/Application\ Support/Google/Chrome/Default/Extensions/ 2>/dev/null
for ext in ~/Library/Application\ Support/Google/Chrome/Default/Extensions/*/; do
  manifest="$ext"$(ls "$ext" | head -1)"/manifest.json"
  if [[ -f "$manifest" ]]; then
    name=$(python3 -c "import json,sys; d=json.load(open('$manifest')); print(d.get('name','?'))" 2>/dev/null)
    echo "$ext | $name"
  fi
done
```

**Flag:** extensions with "all URLs" permission and obscure names.

### Phase 8: SSH Authorized Keys

```bash
cat ~/.ssh/authorized_keys 2>/dev/null
cat ~/.ssh/config
```

**Expected:** only Daniel's iPhone key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZdaMcRK1M9S1hleB2DbBBHfXJyYmyTDNwg+UUBUEoX daniel@iphone`

### Phase 9: Homebrew & Toolchain Architecture

```bash
which brew                   # expect: /opt/homebrew/bin/brew (arm64)
file /opt/homebrew/bin/brew  # expect: Mach-O 64-bit executable arm64
arch                         # expect: arm64
ls /usr/local/bin/ 2>/dev/null | head -20
```

**If `/usr/local/bin/brew` exists:** Intel Homebrew contamination from migration. To remove: `sudo rm -rf /usr/local/Cellar /usr/local/Homebrew /usr/local/bin/brew`.

### Phase 10: Disk & Spotlight Health

```bash
diskutil info disk0 | grep -E "SMART|Media Name|Total Size"
diskutil verifyVolume /
mdutil -s /
```

### Phase 11: Connected Device Verification

```bash
system_profiler SPThunderboltDataType
ioreg -p IOUSB -l -w 0 | grep "USB Product Name"
```

**Expected dock devices:** Logitech BRIO, USB Receiver, EVO 4 USB Audio, Litra Beam, Realtek dock GbE, dock SD reader.
**Expected TB chain:** MacBook → Belkin INC006 → Studio Display, all 40 Gb/s.

### Phase 12: macOS Maintenance (OnyX)

For cache/font/Spotlight cleanup after major updates: `brew install --cask onyx` then run Maintenance → Run All Scripts.

### Quick audit (5 min subset)

```bash
csrutil status
ps aux -r | head -15
lsof -i -P -n | grep LISTEN
file /opt/homebrew/bin/brew
cat /etc/hosts
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT service, client FROM access WHERE auth_value=2 AND service IN ('kTCCServiceAccessibility','kTCCServiceInputMonitoring','kTCCServiceScreenCapture');" 2>/dev/null
```

### Objective-See tools (one-time deep audit)

`brew install --cask knockknock` — also worth: ReiKey, LuLu, BlockBlock.

---

## `update`

Mutates. Runs sequentially. Prints macOS updates but never auto-installs them.

```bash
brew update && brew upgrade && brew upgrade --cask && brew cleanup

# Claude Code (native installer first, then npm, then fresh install)
claude update 2>/dev/null || npm update -g @anthropic-ai/claude-code 2>/dev/null || curl -fsSL https://claude.ai/install.sh | bash

rustup update
uv tool upgrade --all
command -v gcloud &>/dev/null && gcloud components update --quiet
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
command -v tlmgr &>/dev/null && tlmgr update --self --all 2>/dev/null || true
docker info &>/dev/null && docker system prune -f || true
npm cache clean --force 2>/dev/null || true
uv cache clean 2>/dev/null || true

# REPORT ONLY — never auto-install
softwareupdate -l
```

**Safety:** never `softwareupdate -i` without explicit user request. Never auto-reboot.

---

## `power`

Battery, charger, live power draw, top energy consumers, sleep policy. Read-only, ~3s.

### Data collection (no sudo)

```bash
# Battery internals + telemetry
ioreg -rn AppleSmartBattery 2>/dev/null | grep -E '"Amperage"|"Voltage"|"CurrentCapacity"|"DesignCapacity"|"CycleCount"|"IsCharging"|"ExternalConnected"|"BatteryData"|"Watts"|"SystemPowerIn"|"BatteryPower"'

# Charger summary (fast alternative to system_profiler)
pmset -g batt 2>/dev/null

# Top energy consumers (2 samples; discard first for accuracy)
top -l 2 -o power -n 6 -stats pid,command,power 2>/dev/null | tail -10

# Power policy
pmset -g | grep -E "lowpowermode|sleep\b"
```

### Calculations

Prefer `PowerTelemetryData` (milliwatts, real-time) over voltage/amperage estimates:

```python
charger_w  = AdapterDetails["Watts"]
system_w   = PowerTelemetryData["SystemPowerIn"] / 1000
batt_w     = PowerTelemetryData["BatteryPower"] / 1000   # +charging, -discharging

# Fallback if PowerTelemetryData absent:
amp_signed = amp_raw if amp_raw < 2**63 else amp_raw - 2**64
voltage_v  = voltage_mv / 1000
batt_w     = amp_signed * voltage_v / 1000
system_w   = charger_w + abs(batt_w)
```

Extract `FccComp1` / `FccComp2` from `BatteryData` for health, but **don't display health** — Daniel tracks elsewhere.

### Output (print, not markdown)

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  Mac Power Overview                                                     │
  └─────────────────────────────────────────────────────────────────────────┘

  ── Charger ──────────────────────────────────────────────────────────────
  Input                     │  {charger_w}W  {connected}
  System draw               │  ~{system_w:.0f}W  charger {charger_w}W + {abs(batt_w):.1f}W from battery
  Balance                   │  {batt_w:.1f}W from battery  {balance note}

  ── Battery ──────────────────────────────────────────────────────────────
  Charge                    │  {soc}%  ({Charging|Discharging})
  Cycle count               │  {cycles}  Apple warrants 1000 cycles to 80%

  ── Top Energy Consumers ─────────────────────────────────────────────────
  {name:<26}│  {power:>5.1f}  {"█" * int(power/10)}

  ── Power Policy ─────────────────────────────────────────────────────────
  Mode                      │  {Low Power|Automatic}
  Sleep blocked             │  {blocking processes, or "none"}

  ── Recommendations ──────────────────────────────────────────────────────
  {context-driven bullets}
```

Label width 26 chars, separator `│`.

### Recommendation rules (print only when condition holds)

| Condition | Recommendation |
|---|---|
| `charger_w < system_w` | Use a ≥{system_w+5}W charger — current {charger_w}W can't keep up |
| `mediaanalysisd` in top procs | Photos/ML indexing, will stop on its own |
| `caffeinate` in sleep blockers | Kill it if not needed |
| `lowpowermode == 0` and `system_w > 30` | Enable Low Power Mode (`pmset -a lowpowermode 1`) |
| no charger connected | Plug in if doing heavy work |
| no issues | All good. |

### Notes

- Don't show battery health (Daniel tracks elsewhere)
- Don't run `sudo powermetrics` (too slow)
- Don't use `system_profiler SPPowerDataType` (can hang 1–2 min); `pmset -g batt` is the fast alternative
- `top -l 2` takes ~2s; the second sample is accurate
- Process name like `2.1.104` (version string) = likely Electron app; `ps -p {pid} -o comm=` to identify

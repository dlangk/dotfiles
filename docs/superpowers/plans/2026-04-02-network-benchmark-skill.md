# Network Benchmark Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a `/net` skill that surveys the network and runs an adaptive-speed internet benchmark.

**Architecture:** Lightweight skill (SKILL.md) defines the survey commands and invokes the existing `scripts/network-benchmark.sh`. The script is modified to auto-detect link speed and scale payloads accordingly.

**Tech Stack:** Bash, curl, ifconfig, macOS networking tools

---

### Task 1: Add adaptive payload sizing to network-benchmark.sh

**Files:**
- Modify: `scripts/network-benchmark.sh:14-19` (config section)
- Modify: `scripts/network-benchmark.sh:80-86` (warmup section)

- [ ] **Step 1: Add auto-detect function after `detect_connection()`**

Insert after line 48 in `scripts/network-benchmark.sh`:

```bash
# Auto-detect payload size from link speed
detect_payload_size() {
    local media=$(ifconfig "$(route get $PING_TARGET 2>/dev/null | grep interface | awk '{print $2}')" 2>/dev/null | grep media | head -1)
    if echo "$media" | grep -q "10GbaseT\|10Gbase"; then
        echo "2000000000"  # 2GB for 10G
    elif echo "$media" | grep -q "5000baseT"; then
        echo "1000000000"  # 1GB for 5G
    elif echo "$media" | grep -q "2500baseT"; then
        echo "500000000"   # 500MB for 2.5G
    elif echo "$media" | grep -q "1000baseT"; then
        echo "100000000"   # 100MB for 1G
    elif echo "$media" | grep -q "100baseT"; then
        echo "10000000"    # 10MB for 100M
    else
        echo "100000000"   # 100MB fallback
    fi
}
```

- [ ] **Step 2: Replace hardcoded sizes with auto-detection**

Replace lines 16-18:

```bash
SPEEDTEST_SERVER="gbg-shg-speedtest1.bahnhof.net:8080"
DOWNLOAD_SIZE=100000000   # 100MB
UPLOAD_SIZE=100000000     # 100MB
```

With:

```bash
SPEEDTEST_SERVER="gbg-shg-speedtest1.bahnhof.net:8080"
DOWNLOAD_SIZE="${DOWNLOAD_SIZE:-auto}"
UPLOAD_SIZE="${UPLOAD_SIZE:-auto}"
```

- [ ] **Step 3: Resolve auto sizes at the start of `run_internet()`**

Insert at the beginning of `run_internet()` (after `run_internet() {`):

```bash
    # Resolve auto payload sizes
    if [[ "$DOWNLOAD_SIZE" == "auto" ]]; then
        DOWNLOAD_SIZE=$(detect_payload_size)
    fi
    if [[ "$UPLOAD_SIZE" == "auto" ]]; then
        UPLOAD_SIZE=$(detect_payload_size)
    fi

    # Scale warmup to link speed
    local WARMUP_MB=10
    if [[ "$DOWNLOAD_SIZE" -ge 2000000000 ]]; then
        WARMUP_MB=100
    elif [[ "$DOWNLOAD_SIZE" -ge 500000000 ]]; then
        WARMUP_MB=50
    fi
```

- [ ] **Step 4: Update warmup to use scaled size**

Replace the warmup section (lines ~82-86):

```bash
    # Warmup (discard — avoids TCP slow start skewing first run)
    header "Warmup"
    curl -o /dev/null -s "http://$SPEEDTEST_SERVER/download?size=10000000" 2>/dev/null
    dd if=/dev/zero bs=1M count=10 2>/dev/null | \
        curl -X POST -H "Content-Type: application/octet-stream" \
        --data-binary @- -o /dev/null "http://$SPEEDTEST_SERVER/upload" 2>/dev/null
    result "Done (10MB down + 10MB up)"
```

With:

```bash
    # Warmup (discard — avoids TCP slow start skewing first run)
    header "Warmup"
    curl -o /dev/null -s "http://$SPEEDTEST_SERVER/download?size=$((WARMUP_MB * 1000000))" 2>/dev/null
    dd if=/dev/zero bs=1M count=$WARMUP_MB 2>/dev/null | \
        curl -X POST -H "Content-Type: application/octet-stream" \
        --data-binary @- -o /dev/null "http://$SPEEDTEST_SERVER/upload" 2>/dev/null
    result "Done (${WARMUP_MB}MB down + ${WARMUP_MB}MB up)"
```

- [ ] **Step 5: Add detected payload to print_header output**

After the `Media:` line in `print_header()`, add:

```bash
    local payload_bytes=$(detect_payload_size)
    echo "Payload:   $((payload_bytes / 1000000))MB (auto-detected)"
```

- [ ] **Step 6: Test the script**

Run:
```bash
bash scripts/network-benchmark.sh internet 1
```

Expected: shows auto-detected payload size in header, runs with correct size.

- [ ] **Step 7: Commit**

```bash
git add scripts/network-benchmark.sh
git commit -m "Add adaptive payload sizing to network benchmark based on link speed"
```

---

### Task 2: Create /net skill

**Files:**
- Create: `~/.claude/skills/net/SKILL.md`

- [ ] **Step 1: Create the skill file**

```bash
mkdir -p ~/.claude/skills/net
```

Write `~/.claude/skills/net/SKILL.md`:

```markdown
---
name: net
description: "Network survey + speed test. Detects interface, link speed, DNS, latency, and runs adaptive bandwidth benchmark. Triggers on speed test, benchmark, network test, check bandwidth, what speed."
---

# /net

Network survey and adaptive speed benchmark.

## Phase 1: Network Survey

Run all of these in a **single bash call** and present as a summary table:

\```bash
# Active interface and routing
IFACE=$(route get 8.8.8.8 2>/dev/null | grep interface | awk '{print $2}')
GATEWAY=$(route get 8.8.8.8 2>/dev/null | grep gateway | awk '{print $2}')

# Interface details
ifconfig "$IFACE" 2>/dev/null | grep -E "inet |media|status"

# Hardware port name
networksetup -listallhardwareports 2>/dev/null | grep -B1 "$IFACE" | head -1

# Public IP
curl -s --max-time 5 ifconfig.me

# DNS
scutil --dns | grep "nameserver\[0\]" | sort -u

# Quick latency
ping -c 5 -q 8.8.8.8

# First hops
traceroute -n -m 5 -q 1 8.8.8.8

# Wi-Fi details (only if interface is en0 or media is autoselect with no baseT)
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | grep -E "SSID|channel|lastTxRate|agrCtlRSSI|agrCtlNoise" || true
\```

### Output format

Present as a table:

\```
## Network Survey -- YYYY-MM-DD HH:MM TZ

| Property   | Value                              |
|------------|------------------------------------|
| Interface  | en11 (Thunderbolt Ethernet Slot 0) |
| Link speed | 1000baseT (full-duplex)            |
| Local IP   | 192.168.1.13                       |
| Gateway    | 192.168.1.1                        |
| Public IP  | 195.178.184.115                    |
| DNS        | 1.1.1.1                            |
| Latency    | 8.2ms avg to 8.8.8.8              |
| Wi-Fi      | N/A (wired)                        |
\```

If on Wi-Fi, replace the Wi-Fi row with SSID, channel, RSSI, noise, and link rate.

## Phase 2: Internet Benchmark

Run the benchmark script:

\```bash
bash ~/dotfiles/scripts/network-benchmark.sh internet 3
\```

The script auto-detects link speed and scales payloads. No arguments needed.

## Notes

- Survey should complete in <15 seconds
- Benchmark takes 1-2 minutes depending on link speed
- NAS and GCS benchmarks are not included — run the script directly for those
```

- [ ] **Step 2: Verify skill appears**

The skill should show up in the skill list. Test by checking:
```bash
cat ~/.claude/skills/net/SKILL.md | head -5
```

- [ ] **Step 3: Commit**

```bash
git add ~/.claude/skills/net/SKILL.md
git commit -m "Add /net skill for network survey and adaptive speed benchmark"
```

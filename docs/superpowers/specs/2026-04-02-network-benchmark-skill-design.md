# Network Benchmark Skill Design

## Context

Daniel has a comprehensive network benchmark script (`scripts/network-benchmark.sh`) but no skill to invoke it. He frequently tests network speed from different locations (home, office, tethered) and needs a quick survey of the network state before benchmarking. The script also needs adaptive payload sizing — it currently hardcodes 100 MB payloads which are too large for slow links and too small for upcoming 10G.

## Design

### Skill: `/net`

Lightweight skill that runs a two-phase flow: survey then benchmark.

**Invocation:** `/net` (no arguments, single flow)

**Triggers:** "test my network", "speed test", "benchmark network", "check bandwidth", "what speed am I getting"

### Phase 1: Network Survey (skill, inline commands)

Run all commands in a single bash call where possible. Target: <15 seconds.

| Check | Command | Purpose |
|---|---|---|
| Active interface | `route get 8.8.8.8 \| grep interface` | Which interface routes traffic |
| Link speed / media | `ifconfig <iface> \| grep media` | Negotiated speed (1000baseT, 10GbaseT, etc.) |
| IP + gateway | `ifconfig <iface>`, `route get 8.8.8.8 \| grep gateway` | Local IP, default gateway |
| Public IP | `curl -s --max-time 5 ifconfig.me` | External IP / rough location |
| DNS resolvers | `scutil --dns \| grep "nameserver\[0\]" \| sort -u` | Active DNS |
| Latency | `ping -c 5 -q 8.8.8.8` | Baseline RTT |
| First hops | `traceroute -n -m 5 -q 1 8.8.8.8` | Path shape |
| Wi-Fi (if en0) | `/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I` | SSID, channel, RSSI, noise, MCS |

Output as a summary table, then invoke Phase 2.

### Phase 2: Benchmark (script, adaptive)

Invoke `scripts/network-benchmark.sh internet 3`.

The script auto-detects link speed and scales payloads. No arguments needed from the skill.

### Script Changes: Adaptive Payload Sizing

Modify `network-benchmark.sh` to detect link speed at startup and set payload sizes accordingly.

**Detection method:**
```bash
iface=$(route get 8.8.8.8 | grep interface | awk '{print $2}')
media=$(ifconfig "$iface" | grep media | head -1)
```

Parse `media` for speed keywords:

| Media contains | Link speed | `DOWNLOAD_SIZE` / `UPLOAD_SIZE` |
|---|---|---|
| `100baseT` | 100 Mbps | 10 MB (`10000000`) |
| `1000baseT` | 1 Gbps | 100 MB (`100000000`) |
| `2500baseT` | 2.5 Gbps | 500 MB (`500000000`) |
| `5000baseT` | 5 Gbps | 1 GB (`1000000000`) |
| `10GbaseT` or `10Gbase` | 10 Gbps | 2 GB (`2000000000`) |
| (unknown/fallback) | ? | 100 MB (`100000000`) |

**Where to inject:** Replace the hardcoded `DOWNLOAD_SIZE` and `UPLOAD_SIZE` at the top of the script with auto-detection. Only applies to `internet` mode. Keep explicit size overrides if the user wants them (check if already set via env var or argument).

**Warmup scaling:** Scale warmup proportionally — 10 MB warmup for ≤1G, 50 MB for 2.5G+, 100 MB for 10G.

### Files to Create/Modify

| File | Action |
|---|---|
| `~/.claude/skills/net/SKILL.md` | Create — skill definition |
| `scripts/network-benchmark.sh` | Modify — add adaptive sizing |

### Skill Output Format

```
## Network Survey — 2026-04-02 10:30 CET

| Property        | Value                              |
|-----------------|------------------------------------|
| Interface       | en11 (Thunderbolt Ethernet Slot 0) |
| Link speed      | 1000baseT (full-duplex)            |
| Local IP        | 192.168.1.13                       |
| Gateway         | 192.168.1.1                        |
| Public IP       | 195.178.184.115                    |
| DNS             | 1.1.1.1 (Cloudflare)              |
| Latency         | 8.2ms avg to 8.8.8.8              |
| First hop       | 192.168.1.1 (0.5ms)               |
| Wi-Fi           | N/A (wired)                        |

Payload: 100 MB (auto-detected from 1G link)

## Internet Benchmark
[... script output ...]
```

### What This Skill Does NOT Do

- NAS benchmarks (separate concern, requires mount)
- GCS benchmarks (separate concern, requires auth + large payloads)
- Network configuration changes
- DNS changes

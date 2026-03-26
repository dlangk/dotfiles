# Daltorpsgatan Network

## ISP
- **Provider:** Bahnhof
- **Plan:** 1000/1000 Mbps symmetric fiber

## Network Topology

```
🌐 Bahnhof Fiber (1000/1000 Mbps)
    │
    │  fiber optic
    ▼
┌──────────────────────┐
│ Bahnhof Media        │  Fiber ONT (media converter)
│ Converter            │  TX/RX labels, no model number
│                      │  1 Gbps ethernet output
│                      │  ⚠ Known auto-negotiation issues
│                      │    with some 2.5G routers
└──────────┬───────────┘
           │  ethernet
           ▼
┌──────────────────────┐
│ ZyXEL EX3600-T0      │  ISP-provided gateway/router
│ AX6000 Gigabit       │  WiFi 6, all ports gigabit
│ Gateway              │  Adds ~6ms latency
│                      │  Reduces upload by ~29%
└──┬───────────────┬───┘
   │               │
   │  ethernet     │  ethernet
   ▼               ▼
┌────────────┐  ┌──────────────┐
│ Orbi       │  │ Workstation  │
│ AX6000     │  │ (see below)  │
│ (RBK852)   │  └──────────────┘
│ WAN: 2.5G  │
│ LAN: 1G    │
│ WiFi 6     │
│ 5GHz 80MHz │
│ Link: 907  │
│  Mbps      │
└────────────┘
    │  WiFi 6
    ▼
📱 Wireless devices
```

## Workstation Connection Options

### Option A: Belkin INC019 USB-C Gigabit Ethernet Adapter
- USB-C to ethernet + 100W PD pass-through charging
- Detected as: en8 (USB 10/100/1000 LAN)
- Shares USB-C bus with power delivery
- ⚠ PD charging contention may reduce throughput

### Option B: Belkin INC006 Pro Thunderbolt 4 Dock
- Thunderbolt 4 dock with ethernet port
- Detected as: en10 (USB 10/100/1000 LAN)
- Despite Thunderbolt 4 connection (40 Gbps), the dock's internal ethernet
  chip is a USB gigabit NIC on the dock's internal USB hub
- Path: Mac ↔ TB4 (40 Gbps) ↔ dock's USB hub ↔ USB GbE NIC
- This is common — dock manufacturers use $2 USB NICs instead of $15-30
  PCIe NICs. Doesn't matter for this network since everything is gigabit.
- Advantage over INC019: no PD charging contention on the ethernet bus

### Option C: WiFi 6
- Via Orbi AX6000 mesh
- 802.11ax, 5GHz, 80MHz channel, link rate 907 Mbps

### Thunderbolt Dock Port Guide (INC006)
- **Laptop + flash icon** = TB4 upstream to Mac (use this one)
- **Flash only** = TB4 downstream (daisy-chaining devices)
- **USB-C 3.1** = regular USB, no Thunderbolt

## Cable Notes
- Cat 5e or Cat 6: no difference at gigabit speeds
- Cat 5 (not 5e): only specifies 100 Mbps but usually works at gigabit short runs
- Cable category only matters above 1 Gbps (2.5G, 5G, 10G)
- None of the current hardware exceeds gigabit, so cable type is irrelevant

## Benchmark Methodology

### Tool: `~/dotfiles/scripts/network-benchmark.sh`

Replaces `speedtest-cli` (Python, single-threaded, known to underreport upload).

**Method:**
- **Latency:** `ping -c 20 8.8.8.8` (ICMP round-trip)
- **Download:** `curl` GET from Bahnhof Gothenburg speedtest server, 100MB per run
- **Upload:** `curl` POST to same server, 100MB per run (dd → pipe → curl)
- **Warmup:** 10MB down + 10MB up before measured runs (avoids TCP slow start)
- **Runs:** 5 per KPI, report min/avg/max

**Why this method:**
- `curl` is native C — no Python interpreter overhead
- 100MB payloads (was 50MB) reduce variance from connection setup
- Warmup eliminates cold-start penalty on first run
- Download is rock solid (±1 Mbit/s). Upload still has some server-side
  variance (~760-920 Mbit/s) but this is genuine network behavior, not tooling.

**Lesson learned:** `speedtest-cli` (Python) reported ~650-700 Mbps upload
where the real speed was 850-920 Mbps. Never trust speedtest-cli for upload.

### DNS
- Current: Bahnhof (213.80.98.2, 213.80.101.3) via DHCP
- Tested alternatives: Cloudflare (8ms), Quad9 (7ms), Google (12ms), OpenDNS (27ms)
- Bahnhof DNS is 0ms (local to their network) — best option, don't change

## Speed Test Results (2026-03-25/26)

### Summary Table

| Config | Download | Upload | Ping | Method |
|--------|----------|--------|------|--------|
| WiFi (Orbi) → ZyXEL | 607 avg | 588 avg | 16 ms | curl (accurate) |
| INC019 via ZyXEL | 823 avg | 541 avg | 9.4 ms | speedtest-cli (unreliable) |
| INC019 direct to converter | 915 avg | 699 avg | 2.6 ms | speedtest-cli (unreliable) |
| TB4 dock via ZyXEL | 921 avg | 857 avg | 8.2 ms | curl (accurate) |
| TB4 dock direct to converter | 921 avg | 857 avg | 8.2 ms | curl (accurate) |

### WiFi (Orbi AX6000) → ZyXEL (curl, 5 runs + warmup)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 496 | 607 | 692 Mbit/s |
| Upload | 538 | 588 | 611 Mbit/s |
| Ping | 12.4 | 16.0 | 21.4 ms |

WiFi is ~65% of wired speed with more variance. The extra hop through the
Orbi mesh adds ~8ms latency on top of the ZyXEL's ~8ms.

### Final Baseline: TB4 Dock → ZyXEL (curl, 5 runs + warmup)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 921 | 921 | 922 Mbit/s |
| Upload | 763 | 857 | 920 Mbit/s |
| Ping | 8.0 | 8.2 | 8.6 ms |

### Final Baseline: TB4 Dock → Direct to Converter (curl, 5 runs + warmup)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 921 | 921 | 922 Mbit/s |
| Upload | 763 | 857 | 920 Mbit/s |
| Ping | 8.0 | 8.5 | 11.6 ms |

Note: download and upload are effectively the same through the router
and direct — the ZyXEL does not cap throughput. It only adds ~6ms latency.

### Earlier Results (speedtest-cli — kept for reference, upload unreliable)

INC019 via ZyXEL:

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 565 | 823 | 907 Mbit/s |
| Upload | 135 | 541 | 656 Mbit/s |
| Ping | 8.7 | 9.4 | 10.2 ms |

INC019 direct to converter:

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 912 | 915 | 922 Mbit/s |
| Upload | 690 | 699 | 705 Mbit/s |
| Ping | 1.97 | 2.55 | 3.42 ms |

## Analysis

### ZyXEL Router Impact
With accurate measurement (curl), the router does NOT cap throughput.
It adds ~6ms latency (ping 2.6ms direct vs 8.2ms through router).
Earlier speedtest-cli results exaggerated the upload difference.

### INC019 vs TB4 Dock
Download is identical (~921 Mbps). Both use USB gigabit NICs internally.
Upload comparison inconclusive — INC019 was only tested with speedtest-cli
before it got rate-limited. Both adapters likely perform the same.

### Upload Variance
Upload fluctuates 760-920 Mbps even with curl + warmup. This is server-side
or network behavior (Bahnhof speedtest server load, TCP congestion control),
not a local hardware issue. Download being rock solid at 921 ±1 confirms
the local setup is not the bottleneck.

### Why Only 65-75% of Wire Speed on NAS?
Several layers each take a cut from the theoretical 125 MB/s gigabit max:
1. **TCP/IP overhead** — headers, checksums, ACKs → ~940 Mbps real throughput
2. **SMB v3 protocol overhead** — metadata, auth, locking → ~10-15% overhead
3. **NAS CPU (Realtek RTD1619B)** — modest ARM chip, likely the main bottleneck
4. **RAID 1 write penalty** — every write goes to both drives
5. **USB adapter** — small additional latency

Stacked: 125 MB/s × 0.95 (TCP) × 0.88 (SMB) × 0.85 (NAS CPU + RAID + fs) ≈ 80-85 MB/s
Measured: 81.6 MB/s — right in line.

### Protocol Choice for NAS
SMB v3 is optimal for macOS + Synology. NFS has poor write performance on macOS
due to Apple's NFS client implementation. AFP is deprecated. Stick with SMB v3.

### Bottleneck Summary

| Component | Max Speed | Notes |
|-----------|-----------|-------|
| Bahnhof fiber | 1000 Mbps | Plan limit |
| Media converter | 1 Gbps out | Would need upgrade for faster plans |
| ZyXEL EX3600-T0 | ~700-900 NAT | Adds 6ms latency, hurts upload |
| Orbi AX6000 | 2.5G WAN, 1G LAN | LAN ports cap at gigabit |
| Belkin INC019 | 1 Gbps (shared PD) | Performs at line speed |
| Belkin INC006 dock | 1 Gbps (USB NIC) | 914 Mbps upload confirmed |
| Ethernet cables | 1 Gbps (Cat 5e/6) | Not a bottleneck |

## NAS

See `/Volumes/camera/files/nas-docs/benchmark-results.md` for full benchmarks.

- **Device:** Synology DS223 (Realtek RTD1619B ARM CPU)
- **Disks:** 2x WD Red Pro 4TB 7200rpm 256MB cache, RAID 1
- **Storage:** 3.5TB total (2.0TB used, 1.5TB free)
- **Protocol:** SMB v3 (best for macOS + Synology)
- **Hostname:** daltorpsgatan.local, share: `camera`
- **Mount:** /Volumes/camera
- **Best write speed:** 81.6 MB/s over gigabit ethernet (4GB sustained test)

### NAS Speed Comparison

| KPI | WiFi 6 | Gigabit Ethernet | Δ |
|-----|--------|------------------|---|
| Latency | 5.39ms | 4.63ms | 14% ↑ |
| Seq. Write | 46.2 MB/s | 70.9 MB/s | 54% ↑ |
| Small File Create | 19/s | 28/s | 47% ↑ |
| Small File Read | 32/s | 47/s | 47% ↑ |
| Small File Delete | 30/s | 48/s | 60% ↑ |
| Dir Walk (2651 files) | 6.73s | 5.67s | 16% ↑ |

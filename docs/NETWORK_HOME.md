# Daltorpsgatan Network

## Wish List

### ASUS ZenWiFi BQ16 Pro — Orbi replacement candidate
- **WiFi:** WiFi 7, quad-band (2.4GHz + 5GHz + 6GHz×2), 16-stream, 320MHz, 4K-QAM, MLO
- **Ports per node:** 2× 10GbE (WAN/LAN), 1× 1GbE WAN/LAN, 2× 1GbE LAN, 1× USB 3.0
- **Coverage:** 4000 sqft (1-pack), 8000 sqft (2-pack)
- **Price:** ~$700 (1-pack) / ~$1300 (2-pack) USD — check inet.se for SEK pricing
- **Why:** Would replace Orbi RBR850 mesh + provide native 10G backhaul between nodes
- **Consideration:** ZyXEL EE5301-00 (installed April 2026) has WiFi 7 built-in — evaluate
  whether Orbi is still needed before buying
- **Source:** [ASUS ZenWiFi BQ16 Pro](https://www.asus.com/networking-iot-servers/whole-home-mesh-wifi-system/zenwifi-wifi-systems/asus-zenwifi-bq16-pro/)

---

## Current Setup (EE5301 installed April 2026)

### Hardware
- **Router:** ZyXEL EE5301-00 — installed April 2026 (replaced ZyXEL EX3600-T0 + Bahnhof media converter)
- **Mac adapter:** Kalea USB-C 10G — Aquantia AQC113 NIC in an IOCREST Thunderbolt 3 enclosure.
  **Active** as en8, direct to Mac TB4, negotiating 10Gbase-T full-duplex with flow control.
  Thunderbolt link runs at 20 Gb/s (TB3 device) and the NIC sits on PCIe Gen3 x2 (~15.7 Gbit/s),
  both comfortably above what 10GbE needs.
- **ISP plan:** Bahnhof 10G/10G — **active**, measured 8.9 down / 8.3 up Gbit/s payload throughput
  (~9.4 Gbit/s on the wire). See Speed Test Results.

### Topology
```
Bahnhof fiber → SFP+ (WAN, Bahnhof-supplied module + cable)
                ZyXEL EE5301-00
                ├── 10GbE LAN → CAT6 → Kalea 10G USB-C adapter → MBP 14" right TB4 port (direct, not via dock)
                ├── 1GbE LAN  → Orbi AX6000 (RBK852) — WiFi mesh
                └── 1GbE LAN  → Synology DS223 (NAS)
```

### Desk Wiring
```
MacBook Pro 14" M5 Max
├── [LEFT]  TB4 #1 ── Belkin INC006 Dock [⚡🖥 upstream → Mac] (96W charging)
│                     ├── [⚡ downstream] ───── Apple Studio Display (27")
│                     │                         └── USB-C ── Litra Beam (power)
│                     ├── USB-A 3.1 ─────────── EVO Mic Amp → XLR → CL-1 Cloudlifter → XLR → Shure SM7B
│                     ├── USB-A 3.1 ─────────── Logitech BRIO 4K Webcam
│                     └── USB-A 2.0 ─────────── MX 3S receiver
│
└── [RIGHT] TB4 ───── Kalea 10G USB-C adapter → CAT6 → ZyXEL EE5301-00

Bluetooth: Apple Wireless Keyboard, MX 3S (pick one)
Free: USB-A 2.0 × 1, USB-C 3.1 × 1
```

### Verifying connections

Check Thunderbolt topology (dock + display):
```bash
system_profiler SPThunderboltDataType
```
Expected: MacBook Pro → Belkin dock → Studio Display, all at 40 Gb/s.

Check USB devices (all peripherals):
```bash
ioreg -p IOUSB -l -w 0 | grep "USB Product Name"
```
Expected devices:
- `Logitech BRIO` — webcam (via dock)
- `USB Receiver` (Logitech) — MX 3S (via dock)
- `USB Audio` (Generic) — EVO mic amp (via dock)
- `Litra Beam` (Logitech) — via Studio Display
- `USB 10_100_1000 LAN` (Realtek) — dock's built-in ethernet (unused, Kalea preferred)
- `USB Storage` (Generic) — dock's internal SD card reader, always present

Check 10G network interface (once Kalea is connected):
```bash
ifconfig | grep -A 4 en
```
Look for an interface with `media: 10GbaseT` or similar.

Why Kalea goes direct to Mac (not through dock): the dock's USB-C ports are USB 3.2 Gen 2
(10 Gbps theoretical), which can't reliably saturate a 10GbE link after protocol overhead.
Direct TB4 port has 40 Gbps headroom — no bottleneck.

### Notes
- EE5301-00 has WiFi 7 built-in — Orbi may become redundant, evaluate after install
- ISP-locked firmware (Bahnhof controls updates via TR-069/USP)
- Known issue: auto WiFi channel selection causes dropouts — set 2.4GHz to manual channel (1, 6, or 11)
- NAS still 1GbE — NAS transfer speeds unchanged
- 10G baseline established 2026-10-31 (see Speed Test Results). A single TCP stream caps at
  ~4.7 Gbit/s on the Mac, so `network-benchmark.sh` uses 8 parallel streams on 10G links

---

## ISP
- **Provider:** Bahnhof
- **Plan:** 10G/10G symmetric fiber (upgraded from 1G/1G, 2026-03-29)

## Network Topology

```
🌐 Bahnhof Fiber (10G/10G)
    │
    │  fiber → SFP+ (Bahnhof-supplied module)
    ▼
┌──────────────────────┐
│ ZyXEL EE5301-00      │  ISP-provided gateway/router (replaced ONT + EX3600-T0)
│ 10G Gateway          │  WiFi 7 built-in, 10GbE + 1GbE LAN ports
│                      │  Adds ~7ms latency (0.9ms first hop)
│                      │  Passes ~9.4 Gbit/s NAT'd — not a bottleneck
└──┬──────┬────────┬───┘
   │ 1G   │ 1G     │ 10G (CAT6)
   ▼      ▼        ▼
┌────────┐ ┌──────┐ ┌─────────────────────────┐
│ Orbi   │ │ NAS  │ │ Kalea 10G USB-C adapter │
│ AX6000 │ │DS223 │ │ → MBP right TB4 port    │
│(RBK852)│ │ 1GbE │ │ en8, 10Gbase-T          │
│WAN 2.5G│ └──────┘ └─────────────────────────┘
│LAN 1G  │
│WiFi 6  │
└────────┘
    │  WiFi 6 (10.0.0.0/24, Orbi is its own router/DNS at 10.0.0.1)
    ▼
📱 Wireless devices (the Mac's Wi-Fi also lands here; wired en8 wins the default route)
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

### Option D: Kalea 10G USB-C adapter — current
- Aquantia AQC113 10GbE NIC in an IOCREST Thunderbolt 3 enclosure, plugged straight into
  the Mac's right TB4 port (not via the dock — see "Why Kalea goes direct" above)
- Detected as: en8 (`Thunderbolt Ethernet Slot 1`), `media: 10Gbase-T <full-duplex,flow-control>`
- Thunderbolt link 20 Gb/s, PCIe Gen3 x2 — both above 10GbE line rate
- Measured 8.9/8.3 Gbit/s with 8 streams; a single TCP stream caps at ~4.7 Gbit/s (Mac-side limit)
- Check with: `system_profiler SPPCIDataType | grep -A10 0x1d6a` (expect `Link Speed: 8.0 GT/s`, `Link Width: x2`)

### Thunderbolt Dock Port Guide (INC006)
- **Laptop + flash icon** = TB4 upstream to Mac (use this one)
- **Flash only** = TB4 downstream (daisy-chaining devices)
- **USB-C 3.1** = regular USB, no Thunderbolt

## Cable Notes
- Cat 5e or Cat 6: no difference at gigabit speeds
- Cat 5 (not 5e): only specifies 100 Mbps but usually works at gigabit short runs
- Cable category only matters above 1 Gbps (2.5G, 5G, 10G)
- The Mac ↔ EE5301 run is 10GBASE-T over CAT6 (fine up to ~55m; Cat 6a for longer).
  Everything else (Orbi, NAS) is still gigabit, so cable type is irrelevant there

## Benchmark Methodology

### Tool: `~/dotfiles/scripts/network-benchmark.sh`

Replaces `speedtest-cli` (Python, single-threaded, known to underreport upload).

**Method:**
- **Latency:** `ping -c 20 8.8.8.8` (ICMP round-trip)
- **Download:** `curl` GET from Bahnhof Gothenburg speedtest server. Payload scales with
  link speed (100MB at 1G, 500MB at 2.5G, 1GB at 5G, 4GB at 10G) and is split across
  parallel streams (1 at ≤1G, 2 at 2.5G, 4 at 5G, 8 at 10G). Reported speed is total
  bytes moved / wall time across all streams, timed from one Python process.
- **Upload:** `curl` POST to same server (dd → pipe → curl), same stream split. Capped at
  500MB per stream / 2GB total because curl buffers the request body in memory.
- **Warmup:** single-stream down + up before measured runs, scaled with payload
  (10MB at 1G, 200MB at 10G) — avoids TCP slow start skewing the first run
- **Runs:** 5 per KPI by default (`/network test` uses 3), report min/avg/max
- **Streams:** `STREAMS=auto` (default, scales as above) or `STREAMS=1` to measure what a
  single scp/curl connection will see

**Why this method:**
- `curl` is native C — no Python interpreter overhead
- 100MB payloads (was 50MB) reduce variance from connection setup
- Warmup eliminates cold-start penalty on first run
- Download is rock solid (±1 Mbit/s at 1G, ±2% at 10G). Upload has some server-side
  variance but this is genuine network behavior, not tooling.
- Parallel streams: one TCP connection tops out around 4.7 Gbit/s on the M5 Max at
  MTU 1500. RTT to the Bahnhof server is ~1ms, so the 4MB macOS socket buffers are
  not the limit (BDP is tiny); it is per-core packet processing in one curl + one
  kernel receive path, plus whatever per-connection cap the server applies. 4 streams
  reach ~9.1 Gbit/s on the wire, 8 streams ~9.4 Gbit/s — effectively 10GbE line rate.
- Reported numbers count HTTP payload only. Interface byte counters run ~4-6% higher
  (TCP/IP/TLS framing), so 8.9 Gbit/s payload ≈ 9.4 Gbit/s on the wire.

**Lesson learned:** `speedtest-cli` (Python) reported ~650-700 Mbps upload
where the real speed was 850-920 Mbps. Never trust speedtest-cli for upload.

### DNS
- Current: Bahnhof (213.80.98.2, 213.80.101.3) via DHCP
- Tested alternatives: Cloudflare (8ms), Quad9 (7ms), Google (12ms), OpenDNS (27ms)
- Bahnhof DNS is 0ms (local to their network) — best option, don't change

## Speed Test Results

### Summary Table

| Config | Download | Upload | Ping | Method | Date |
|--------|----------|--------|------|--------|------|
| WiFi (Orbi) → ZyXEL | 607 avg | 588 avg | 16 ms | curl | 2026-03-25 |
| INC019 via ZyXEL | 823 avg | 541 avg | 9.4 ms | speedtest-cli (unreliable) | 2026-03-25 |
| INC019 direct to converter | 915 avg | 699 avg | 2.6 ms | speedtest-cli (unreliable) | 2026-03-25 |
| TB4 dock via ZyXEL | 921 avg | 857 avg | 8.2 ms | curl | 2026-03-26 |
| TB4 dock direct to converter | 921 avg | 857 avg | 8.2 ms | curl | 2026-03-26 |
| USB 2.5G adapter via ZyXEL | 845 avg | 912 avg | 8.6 ms | curl | 2026-03-29 |
| Kalea 10G (direct TB4) via EX3600 (1G) | 904 avg | 916 avg | 8.2 ms | curl | 2026-03-30 |
| Kalea 10G via EE5301, 1 stream | 4690 avg | 3394 avg | 8.1 ms | curl ×1, 2GB | 2026-10-31 |
| **Kalea 10G via EE5301, 8 streams** | **8855 avg** | **8290 avg** | **8.2 ms** | **curl ×8, 4GB** | **2026-10-31** |

### 10G Baseline: Kalea 10G → EE5301 (curl, 8 streams, 4GB down / 2GB up, 3 runs + warmup)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 8659 | 8855 | 8959 Mbit/s |
| Upload | 8211 | 8290 | 8397 Mbit/s |
| Ping (8.8.8.8) | 8.1 | 8.2 | 8.3 ms |

Payload throughput; interface counters showed ~9.4 Gbit/s on the wire. First hop (router)
0.9 ms, RTT to the Bahnhof speedtest server ~1 ms, zero input/output errors on en8.

### Single-Stream Reference: same path, `STREAMS=1` (curl, 2GB down / 500MB up, 3 runs)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 4654 | 4690 | 4714 Mbit/s |
| Upload | 3351 | 3394 | 3421 Mbit/s |

This is what a single scp, curl or browser connection gets. Multi-connection workloads
(gcloud parallel composite uploads, SMB multichannel, browsers) see the full rate.

### WiFi (Orbi AX6000) → ZyXEL (curl, 5 runs + warmup)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 496 | 607 | 692 Mbit/s |
| Upload | 538 | 588 | 611 Mbit/s |
| Ping | 12.4 | 16.0 | 21.4 ms |

WiFi is ~65% of wired speed with more variance. The extra hop through the
Orbi mesh adds ~8ms latency on top of the ZyXEL's ~8ms.

### Gigabit Baseline (pre-EE5301): TB4 Dock → EX3600 (curl, 5 runs + warmup)

| KPI | Min | Avg | Max |
|-----|-----|-----|-----|
| Download | 921 | 921 | 922 Mbit/s |
| Upload | 763 | 857 | 920 Mbit/s |
| Ping | 8.0 | 8.2 | 8.6 ms |

### Gigabit Baseline (pre-EE5301): TB4 Dock → Direct to Converter (curl, 5 runs + warmup)

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

### Single-Stream Ceiling at 10G (2026-10-31)
The first 10G benchmark reported 4717 Mbit/s and looked like a link problem. It was not:
one curl stream hit ~4.7-5.0 Gbit/s, 4 parallel streams 9.1 Gbit/s, 8 streams 9.4 Gbit/s
(wire). Ruled out: adapter PCIe link (Gen3 x2, 15.7 Gbit/s), Thunderbolt link (20 Gb/s),
interface errors (none), router NAT (passes 9.4 Gbit/s). The ceiling is per TCP
connection on the Mac — single-core packet processing at MTU 1500, ~400k packets/s.
Jumbo frames would raise it but the ISP path won't carry them end to end.

### ZyXEL Router Impact
With accurate measurement (curl), neither ZyXEL (EX3600 at 1G, EE5301 at 10G) caps
throughput. The EX3600 added ~6ms latency (ping 2.6ms direct vs 8.2ms through router);
the EE5301 is the same ~8.2ms to 8.8.8.8 with 0.9ms to the first hop.
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
| Bahnhof fiber | 10 Gbps | Upgraded 2026-03-29; measured 8.9/8.3 Gbit/s payload |
| ZyXEL EE5301-00 | 10 Gbps | Installed April 2026; passes ~9.4 Gbit/s NAT'd — not a bottleneck |
| Kalea 10G adapter | 10 Gbps | AQC113, PCIe Gen3 x2 over TB3 (20 Gb/s link) — line rate |
| Single TCP stream (Mac) | ~4.7 Gbit/s | **Per-connection ceiling** — needs parallel streams to fill the link |
| Orbi AX6000 | 2.5G WAN, 1G LAN | LAN ports cap at gigabit; Wi-Fi clients ~600 Mbit/s |
| Synology DS223 | 1 Gbps | NAS still on 1GbE |
| Belkin INC019 | 1 Gbps (shared PD) | Performs at line speed (retired from the desk) |
| Belkin INC006 dock | 1 Gbps (USB NIC) | 914 Mbps upload confirmed; unused for routing |
| Ethernet cables | CAT6 to Mac (10G), Cat 5e/6 elsewhere | Not a bottleneck |

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

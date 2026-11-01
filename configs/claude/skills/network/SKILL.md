---
name: network
description: Network survey, device inventory, and adaptive speed benchmark. Verbs:`status` (default — interface, link speed, DNS, latency, connected devices, VPN), `test` (adaptive bandwidth benchmark). Triggers on network status, speed test, benchmark, bandwidth, what speed, network test, check connectivity.
---

# /network

Network survey + speed test on whatever machine you're running it from.

## Invocation

```
/network [verb] [--flag...]
```

**Verbs** (default: `status`):

| Verb | Side effects | Roughly takes |
|---|---|---|
| `status` | none | 5–10s |
| `test`   | none persistent; sends up to ~6GB up + ~12GB down on 10G (less on slower links) | 30–90s |

See `~/.claude/skills/CONVENTIONS.md` for universal flags. `--quiet` skips the device table and prints only the internet path.

---

## `status`

Read-only survey. Single bash call.

```bash
IFACE=$(route get 8.8.8.8 2>/dev/null | grep interface | awk '{print $2}')
GATEWAY=$(route get 8.8.8.8 2>/dev/null | grep gateway | awk '{print $2}')
echo "=== IFACE: $IFACE ==="
echo "=== GATEWAY: $GATEWAY ==="
ifconfig "$IFACE" 2>/dev/null | grep -E "inet |media|status|ether"
echo "=== HWPORT ==="
networksetup -listallhardwareports 2>/dev/null | grep -B1 "$IFACE" | head -1
echo "=== ROUTER ARP ==="
arp -n "$GATEWAY" 2>/dev/null
echo "=== PUBLIC IP ==="
curl -s --max-time 5 -4 ifconfig.me
echo
echo "=== DNS ==="
scutil --dns | grep "nameserver\[0\]" | sort -u
ipconfig getpacket "$IFACE" 2>/dev/null | grep domain_name_server
echo "=== LATENCY ==="
ping -c 5 -q 8.8.8.8
echo "=== TRACEROUTE ==="
traceroute -n -m 5 -q 1 8.8.8.8 2>&1
echo "=== WIFI ==="
# `airport` is deprecated (Sonoma+); `wdutil info` needs sudo but returns real SSID/RSSI/channel.
if networksetup -listallhardwareports 2>/dev/null | grep -B1 "$IFACE" | grep -q "Wi-Fi"; then
  sudo wdutil info 2>/dev/null | awk '/WIFI/{f=1} f && /^----/{c++; if(c==2)exit} f && /SSID|BSSID|RSSI|Noise|Channel|Tx Rate|PHY Mode|Security/{print}'
else
  echo "Not on Wi-Fi"
fi
echo "=== OUI ==="
source ~/dotfiles/scripts/oui-lookup.sh
ADAPTER_MAC=$(ifconfig "$IFACE" 2>/dev/null | grep ether | awk '{print $2}' | cut -c1-8)
ROUTER_MAC=$(arp -n "$GATEWAY" 2>/dev/null | awk '{print $4}' | cut -c1-8)
echo "Adapter: $(oui_lookup "$ADAPTER_MAC")"
echo "Router: $(oui_lookup "$ROUTER_MAC")"
echo "=== USB ==="
ioreg -p IOUSB -l -w 0 2>/dev/null | grep "USB Product Name" | sed 's/.*= "\(.*\)"/\1/'
echo "=== THUNDERBOLT ==="
system_profiler SPThunderboltDataType 2>/dev/null | grep -A2 "Device Name" | grep "Device Name" | sed 's/.*: //' | grep -v "MacBook Pro"
echo "=== BLUETOOTH ==="
system_profiler SPBluetoothDataType 2>/dev/null | grep -B1 "Connected: Yes" | grep "Name:" | sed 's/.*Name: //' || echo "None connected"
echo "=== VPN ==="
mullvad status 2>/dev/null || echo "mullvad-cli: not found"
nordvpn status 2>/dev/null || echo "nordvpn-cli: not found"
# Fallback: utun interfaces (VPN tunnels show up here)
for t in $(ifconfig -l | tr ' ' '\n' | grep '^utun'); do
  IP=$(ifconfig $t 2>/dev/null | grep "inet " | awk '{print $2}')
  [ -n "$IP" ] && echo "  $t: $IP"
done
```

---

## `test`

Active bandwidth benchmark. Sends traffic.

```bash
bash ~/dotfiles/scripts/network-benchmark.sh internet 3
```

Outputs a `RESULT|dl_avg|dl_min|dl_max|ul_avg|ul_min|ul_max|latency_ms|payload_mb|runs|streams` line.

`streams` is the number of parallel TCP connections per run (auto: 1 at ≤1G, 2 at 2.5G, 4 at 5G,
8 at 10G). A single stream caps at ~4.7 Gbit/s on the Mac, so on 10G the aggregate is the link speed
and `STREAMS=1 bash ~/dotfiles/scripts/network-benchmark.sh internet 3` gives the single-connection number.

Implies `status` first — always show the network context alongside the speed results so a slow result isn't reported without saying which VPN/adapter it was measured on.

---

## Output

Wait until both data collections complete before printing anything. Then:

```
Network at <site>: <iface> <link>, <down>/<up> Mbit/s, <vpn or 'no VPN'>

## Devices
| Device | Connection |
|---|---|
| Belkin Pro TB4 Dock | Thunderbolt 4 |
| Apple Studio Display | TB4 via dock |
| ... | ... |

## Internet Path
| Property | Value |
|---|---|
| Adapter | en8 — Kalea 10G USB-C (10Gbase-T, full-duplex) |
| Local IP | 192.168.1.13 |
| Router | 192.168.1.1 — ZyXEL EE5301-00 |
| Public IP | 94.254.62.90 |
| VPN | Mullvad — Connected (utun5, 10.x.x.x) — or "None" |
| DNS | 192.168.1.1 |
| Latency | 8.3ms avg, first hop 0.5ms |

## Benchmark   (only on `test`)
| Metric | Avg | Min | Max |
|---|---|---|---|
| Download | 9122 Mbit/s (1140 MB/s) | 9111 | 9129 |
| Upload   | 8605 Mbit/s (1076 MB/s) | 8466 | 8808 |
| Latency  | 8.3ms |   |   |
| Payload  | 4000 MB | Runs: 3 | Streams: 8 |
```

Show speeds as `X Mbit/s (Y MB/s)` where Y = X / 8, rounded to whole number.

- Omit the Wi-Fi row when on wired.
- Bluetooth devices go in the Devices table with "Bluetooth" as connection type — omit if none.
- `--quiet` collapses to the first summary line + benchmark numbers (no tables).
- `--verbose` adds the raw bash output below each table.

---

## Device name lookups

Two mapping files in `~/dotfiles/docs/`:

- `device-names.txt` — MAC OUI → friendly name (adapter, router)
- `usb-devices.txt`  — USB vendor:product → friendly name (peripherals)

When building the Devices table, look up each USB device by vendor:product:
```bash
grep "^${idVendor}:${idProduct} " ~/dotfiles/docs/usb-devices.txt | sed 's/^[^ ]* //'
```

If matched, use the friendly name. Skip hub entries (`USB2.0 Hub`, `USB3 Gen2 Hub`, etc.) — infrastructure, not peripherals.

---

## Unrecognized devices

After printing the tables, prompt the user for any unknown OUIs or USB IDs:

> "I found [manufacturer] for MAC [prefix] — what's the friendly name?"
> "I see a USB device called **[raw name]** (vendor:product `XXXX:XXXX`) — do you know what it is?"

Save additions to `~/dotfiles/docs/device-names.txt` / `usb-devices.txt`. Ask one at a time.

---

## VPN detection

Daniel runs **Mullvad** as primary, **NordVPN** as fallback (used in China where Mullvad is blocked).

- `mullvad status` shows "Connected" → report "Mullvad — Connected"
- `nordvpn status` shows "Connected" → report "NordVPN — Connected"
- Otherwise fall back to `utunN` with a `10.x.x.x` address → likely a VPN tunnel
- If none → "None" (omit the row only on a trusted home network)

---

## Notes

- OUI file (`~/.local/share/oui.txt`) auto-downloads on first use, refreshes monthly on ≥1G links
- NAS and GCS benchmarks aren't in `test` — run the script directly for those

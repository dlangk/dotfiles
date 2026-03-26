#!/bin/bash
set -e

# Network Benchmark Suite
# Usage: ./network-benchmark.sh [all|internet|nas] [runs]
# Example: ./network-benchmark.sh all 5
#          ./network-benchmark.sh internet 3
#          ./network-benchmark.sh nas 5

MODE="${1:-all}"
RUNS="${2:-5}"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

# Internet test config
SPEEDTEST_SERVER="gbg-shg-speedtest1.bahnhof.net:8080"
DOWNLOAD_SIZE=100000000   # 100MB
UPLOAD_SIZE=100000000     # 100MB
PING_TARGET="8.8.8.8"
PING_COUNT=20

# NAS test config
NAS_MOUNT="/Volumes/camera"
NAS_WRITE_MB=1024
NAS_SMALL_FILES=1000

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

header()  { echo -e "\n${CYAN}=== $1 ===${NC}"; }
result()  { echo -e "${GREEN}  $1${NC}"; }
warning() { echo -e "${YELLOW}  $1${NC}"; }

# Detect connection
detect_connection() {
    local iface=$(route get $PING_TARGET 2>/dev/null | grep interface | awk '{print $2}')
    local hwport=$(networksetup -listallhardwareports 2>/dev/null | grep -B1 "$iface" | head -1 | sed 's/Hardware Port: //')
    local media=$(ifconfig "$iface" 2>/dev/null | grep media | head -1 | sed 's/.*(\(.*\))/\1/')
    echo "$iface|$hwport|$media"
}

print_header() {
    local conn=$(detect_connection)
    local iface=$(echo "$conn" | cut -d'|' -f1)
    local hwport=$(echo "$conn" | cut -d'|' -f2)
    local media=$(echo "$conn" | cut -d'|' -f3)

    echo "╔══════════════════════════════════════════╗"
    echo "║       Network Benchmark Suite            ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "Date:      $(date)"
    echo "Mode:      $MODE"
    echo "Runs:      $RUNS"
    echo "Interface: $iface ($hwport)"
    echo "Media:     $media"
}

# ─── Internet Benchmark ───

run_internet() {
    header "Internet Benchmark"
    echo "  Server: $SPEEDTEST_SERVER"
    echo "  Download: $((DOWNLOAD_SIZE/1000000))MB × $RUNS runs"
    echo "  Upload: $((UPLOAD_SIZE/1000000))MB × $RUNS runs"

    # Latency
    header "Latency ($PING_COUNT pings → $PING_TARGET)"
    ping_result=$(ping -c $PING_COUNT -q $PING_TARGET 2>&1 | tail -1)
    result "$ping_result"

    # Warmup (discard — avoids TCP slow start skewing first run)
    header "Warmup"
    curl -o /dev/null -s "http://$SPEEDTEST_SERVER/download?size=10000000" 2>/dev/null
    dd if=/dev/zero bs=1M count=10 2>/dev/null | \
        curl -X POST -H "Content-Type: application/octet-stream" \
        --data-binary @- -o /dev/null "http://$SPEEDTEST_SERVER/upload" 2>/dev/null
    result "Done (10MB down + 10MB up)"

    # Download via curl
    local DL_MB=$((DOWNLOAD_SIZE / 1000000))
    header "Download (${DL_MB}MB × $RUNS runs)"
    local dl_results=()
    for i in $(seq 1 $RUNS); do
        local bytes_sec=$(curl -o /dev/null -w "%{speed_download}" \
            "http://$SPEEDTEST_SERVER/download?size=$DOWNLOAD_SIZE" 2>/dev/null)
        local mbps=$(python3 -c "print(f'{$bytes_sec * 8 / 1_000_000:.0f}')")
        dl_results+=("$mbps")
        result "Run $i: ${mbps} Mbit/s"
    done

    # Download summary
    python3 -c "
r = [$(IFS=,; echo "${dl_results[*]}")]
print(f'\033[0;32m  → Min={min(r):.0f}  Avg={sum(r)/len(r):.0f}  Max={max(r):.0f} Mbit/s\033[0m')
"

    # Upload via curl (generate payload with dd, pipe to curl)
    local UL_MB=$((UPLOAD_SIZE / 1000000))
    header "Upload (${UL_MB}MB × $RUNS runs)"
    local ul_results=()
    for i in $(seq 1 $RUNS); do
        local bytes_sec=$(dd if=/dev/zero bs=1M count=$UL_MB 2>/dev/null | \
            curl -X POST -H "Content-Type: application/octet-stream" \
            --data-binary @- -w "%{speed_upload}" \
            -o /dev/null "http://$SPEEDTEST_SERVER/upload" 2>/dev/null)
        local mbps=$(python3 -c "print(f'{$bytes_sec * 8 / 1_000_000:.0f}')")
        ul_results+=("$mbps")
        result "Run $i: ${mbps} Mbit/s"
    done

    # Upload summary
    python3 -c "
r = [$(IFS=,; echo "${ul_results[*]}")]
print(f'\033[0;32m  → Min={min(r):.0f}  Avg={sum(r)/len(r):.0f}  Max={max(r):.0f} Mbit/s\033[0m')
"

    # Overall summary
    header "Internet Summary"
    python3 -c "
dl = [$(IFS=,; echo "${dl_results[*]}")]
ul = [$(IFS=,; echo "${ul_results[*]}")]
print(f'\033[0;32m  Download: {sum(dl)/len(dl):.0f} Mbit/s avg ({min(dl):.0f}-{max(dl):.0f})\033[0m')
print(f'\033[0;32m  Upload:   {sum(ul)/len(ul):.0f} Mbit/s avg ({min(ul):.0f}-{max(ul):.0f})\033[0m')
"
}

# ─── NAS Benchmark ───

run_nas() {
    if ! mount | grep -q "$NAS_MOUNT"; then
        warning "NAS not mounted at $NAS_MOUNT — skipping NAS benchmark"
        return
    fi

    header "NAS Benchmark"
    echo "  Mount: $NAS_MOUNT"
    echo "  Write: ${NAS_WRITE_MB}MB | Small files: ${NAS_SMALL_FILES}"

    local BENCH_DIR="$NAS_MOUNT/.nas-benchmark-$$"
    local LARGE_FILE="$BENCH_DIR/large_test_file"
    local SMALL_DIR="$BENCH_DIR/small_files"

    mkdir -p "$BENCH_DIR" "$SMALL_DIR"
    trap "rm -rf '$BENCH_DIR' 2>/dev/null" EXIT

    # NAS Latency
    header "NAS Latency (100 stats)"
    start=$(python3 -c "import time; print(time.time())")
    for i in $(seq 1 100); do stat "$NAS_MOUNT" > /dev/null 2>&1; done
    end=$(python3 -c "import time; print(time.time())")
    avg=$(python3 -c "print(f'{($end - $start) / 100 * 1000:.2f}')")
    result "Avg stat latency: ${avg}ms"

    # Sequential write
    header "NAS Sequential Write (${NAS_WRITE_MB}MB)"
    sync
    start=$(python3 -c "import time; print(time.time())")
    dd if=/dev/zero of="$LARGE_FILE" bs=1M count=$NAS_WRITE_MB 2>/dev/null
    sync
    end=$(python3 -c "import time; print(time.time())")
    duration=$(python3 -c "print(f'{$end - $start:.2f}')")
    speed=$(python3 -c "print(f'{$NAS_WRITE_MB / ($end - $start):.1f}')")
    result "Wrote ${NAS_WRITE_MB}MB in ${duration}s = ${speed} MB/s"

    # Sequential read (note: may be cached by macOS)
    header "NAS Sequential Read (${NAS_WRITE_MB}MB)"
    start=$(python3 -c "import time; print(time.time())")
    dd if="$LARGE_FILE" of=/dev/null bs=1M 2>/dev/null
    end=$(python3 -c "import time; print(time.time())")
    duration=$(python3 -c "print(f'{$end - $start:.2f}')")
    speed=$(python3 -c "print(f'{$NAS_WRITE_MB / ($end - $start):.1f}')")
    result "Read ${NAS_WRITE_MB}MB in ${duration}s = ${speed} MB/s"
    warning "(may be cached — run 'sudo purge' before for accurate read)"

    rm -f "$LARGE_FILE"

    # Small file create
    header "NAS Small File Create (${NAS_SMALL_FILES} files)"
    start=$(python3 -c "import time; print(time.time())")
    for i in $(seq 1 $NAS_SMALL_FILES); do
        echo "test data $i" > "$SMALL_DIR/file_$i.txt"
    done
    sync
    end=$(python3 -c "import time; print(time.time())")
    duration=$(python3 -c "print(f'{$end - $start:.2f}')")
    rate=$(python3 -c "print(f'{$NAS_SMALL_FILES / ($end - $start):.0f}')")
    result "Created ${NAS_SMALL_FILES} files in ${duration}s = ${rate} files/s"

    # Small file read
    header "NAS Small File Read (${NAS_SMALL_FILES} files)"
    start=$(python3 -c "import time; print(time.time())")
    for i in $(seq 1 $NAS_SMALL_FILES); do
        cat "$SMALL_DIR/file_$i.txt" > /dev/null
    done
    end=$(python3 -c "import time; print(time.time())")
    duration=$(python3 -c "print(f'{$end - $start:.2f}')")
    rate=$(python3 -c "print(f'{$NAS_SMALL_FILES / ($end - $start):.0f}')")
    result "Read ${NAS_SMALL_FILES} files in ${duration}s = ${rate} files/s"

    # Directory walk
    header "NAS Directory Walk"
    start=$(python3 -c "import time; print(time.time())")
    count=$(find "$NAS_MOUNT" -maxdepth 3 -type f 2>/dev/null | wc -l | tr -d ' ')
    end=$(python3 -c "import time; print(time.time())")
    duration=$(python3 -c "print(f'{$end - $start:.2f}')")
    result "Found ${count} files (depth 3) in ${duration}s"

    # Small file delete
    header "NAS Small File Delete (${NAS_SMALL_FILES} files)"
    start=$(python3 -c "import time; print(time.time())")
    rm -f "$SMALL_DIR"/file_*.txt
    sync
    end=$(python3 -c "import time; print(time.time())")
    duration=$(python3 -c "print(f'{$end - $start:.2f}')")
    rate=$(python3 -c "print(f'{$NAS_SMALL_FILES / ($end - $start):.0f}')")
    result "Deleted ${NAS_SMALL_FILES} files in ${duration}s = ${rate} files/s"

    rm -rf "$BENCH_DIR"
    trap - EXIT
}

# ─── Main ───

print_header
echo ""

case "$MODE" in
    internet) run_internet ;;
    nas)      run_nas ;;
    all)      run_internet; run_nas ;;
    *)        echo "Usage: $0 [all|internet|nas] [runs]"; exit 1 ;;
esac

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Benchmark complete                 ║"
echo "╚══════════════════════════════════════════╝"

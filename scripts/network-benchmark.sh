#!/bin/bash
set -e

# Network Benchmark Suite
# Usage: ./network-benchmark.sh [all|internet|nas|gcs] [runs]
# Example: ./network-benchmark.sh all 5
#          ./network-benchmark.sh internet 3
#          STREAMS=1 ./network-benchmark.sh internet 3   # single-connection speed
#          ./network-benchmark.sh nas 5
#          ./network-benchmark.sh gcs 3

MODE="${1:-all}"
RUNS="${2:-5}"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

# Internet test config
SPEEDTEST_SERVER="gbg-shg-speedtest1.bahnhof.net:8080"
DOWNLOAD_SIZE="${DOWNLOAD_SIZE:-auto}"
UPLOAD_SIZE="${UPLOAD_SIZE:-auto}"
# Parallel TCP streams per run. A single stream tops out around 5 Gbit/s on
# this Mac (per-core packet processing at MTU 1500, ~1ms RTT to the Bahnhof
# server), so anything above 2.5G needs several streams to measure the link
# rather than one socket. "auto" scales with link speed; set STREAMS=1 to
# measure single-connection throughput (what one scp/curl will see).
STREAMS="${STREAMS:-auto}"
PING_TARGET="8.8.8.8"
PING_COUNT=20

# NAS test config
NAS_MOUNT="/Volumes/camera"
NAS_WRITE_MB=1024
NAS_SMALL_FILES=1000

# GCS test config
GCS_BUCKET="gs://langkilde-backup"
GCS_TEST_DIR="speedtest"
GCS_FILE_SIZE_MB=20480  # 20GB — must be large to amortize gcloud overhead at 10G speeds

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

# Negotiated link speed in Mbit/s, from ifconfig media (1000 if unknown)
detect_link_mbps() {
    local media=$(ifconfig "$(route get $PING_TARGET 2>/dev/null | grep interface | awk '{print $2}')" 2>/dev/null | grep media | head -1)
    if echo "$media" | grep -q "10GbaseT\|10Gbase"; then echo 10000
    elif echo "$media" | grep -q "5000baseT"; then echo 5000
    elif echo "$media" | grep -q "2500baseT"; then echo 2500
    elif echo "$media" | grep -q "1000baseT"; then echo 1000
    elif echo "$media" | grep -q "100baseT"; then echo 100
    else echo 1000
    fi
}

# Auto-detect payload size from link speed
detect_payload_size() {
    case "$(detect_link_mbps)" in
        10000) echo "4000000000" ;;  # 4GB for 10G (~4s per run; amortizes TLS/redirect setup across 8 streams)
        5000)  echo "1000000000" ;;  # 1GB for 5G
        2500)  echo "500000000" ;;   # 500MB for 2.5G
        100)   echo "10000000" ;;    # 10MB for 100M
        *)     echo "100000000" ;;   # 100MB for 1G / fallback
    esac
}

# Auto-detect parallel streams from link speed (see STREAMS above)
detect_streams() {
    case "$(detect_link_mbps)" in
        10000) echo 8 ;;
        5000)  echo 4 ;;
        2500)  echo 2 ;;
        *)     echo 1 ;;
    esac
}

resolve_streams() {
    if [[ "$STREAMS" == "auto" ]]; then STREAMS=$(detect_streams); fi
}

print_header() {
    local conn=$(detect_connection)
    local iface=$(echo "$conn" | cut -d'|' -f1)
    local media=$(echo "$conn" | cut -d'|' -f3)
    local payload_bytes=$(detect_payload_size)
    resolve_streams
    echo "Network Benchmark | $iface ($media) | $((payload_bytes / 1000000))MB payload | $STREAMS streams | $RUNS runs"
}

# Run one measured transfer: N parallel curl streams, each moving total/N
# bytes, and report aggregate Mbit/s = total bytes actually moved / wall time.
# Measured from inside one python process so the clock brackets only the
# transfers, not shell fork overhead.
#   parallel_transfer download|upload <total_bytes> <streams>
parallel_transfer() {
    python3 - "$1" "$2" "$3" "$SPEEDTEST_SERVER" <<'PY'
import subprocess, sys, time
mode, total, n, server = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
per = total // n
if mode == "download":
    # -L: Bahnhof's server 307-redirects http:8080 to its https Ookla host
    cmd = (f"curl -L -s -o /dev/null -w '%{{size_download}}' "
           f"'http://{server}/download?size={per}'")
else:
    # curl's --data-binary @- buffers the whole stream in memory; the caller
    # caps the total so n streams together stay well within budget.
    cmd = (f"dd if=/dev/zero bs=1M count={per // 1_000_000} 2>/dev/null | "
           f"curl -L -s -X POST -H 'Content-Type: application/octet-stream' "
           f"--data-binary @- -o /dev/null -w '%{{size_upload}}' "
           f"'http://{server}/upload'")
start = time.monotonic()
procs = [subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, text=True) for _ in range(n)]
outs = [p.communicate()[0].strip() for p in procs]
elapsed = time.monotonic() - start
moved = sum(int(o) for o in outs if o.isdigit())
print(f"{moved * 8 / (elapsed * 1_000_000):.0f}" if elapsed > 0 and moved > 0 else "0")
PY
}

# ─── Internet Benchmark ───

run_internet() {
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
        WARMUP_MB=200
    elif [[ "$DOWNLOAD_SIZE" -ge 500000000 ]]; then
        WARMUP_MB=50
    fi

    resolve_streams

    local DL_MB=$((DOWNLOAD_SIZE / 1000000))
    local UL_MB=$((UPLOAD_SIZE / 1000000))

    echo "Benchmarking: ${DL_MB}MB payload, $STREAMS streams, $RUNS runs, server $SPEEDTEST_SERVER"

    # Latency
    echo -n "Latency: "
    ping_result=$(ping -c $PING_COUNT -q $PING_TARGET 2>&1 | tail -1)
    echo "$ping_result"

    # Warmup (discard — avoids TCP slow start skewing first run)
    echo -n "Warmup (${WARMUP_MB}MB)... "
    curl -L -o /dev/null -s "http://$SPEEDTEST_SERVER/download?size=$((WARMUP_MB * 1000000))" 2>/dev/null
    dd if=/dev/zero bs=1M count=$WARMUP_MB 2>/dev/null | \
        curl -L -X POST -H "Content-Type: application/octet-stream" \
        --data-binary @- -o /dev/null "http://$SPEEDTEST_SERVER/upload" 2>/dev/null
    echo "done"

    # Download: STREAMS parallel curls, DOWNLOAD_SIZE bytes in total per run
    local dl_results=()
    for i in $(seq 1 $RUNS); do
        echo -n "Download $i/$RUNS (${DL_MB}MB x $STREAMS streams)... "
        local mbps=$(parallel_transfer download "$DOWNLOAD_SIZE" "$STREAMS")
        dl_results+=("${mbps:-0}")
        echo "${mbps:-0} Mbit/s"
    done

    # Upload. curl's --data-binary @- buffers its entire stream in memory, so
    # cap the payload at 500MB per stream (max 2GB total) regardless of link
    # speed. 2GB across 8 streams at ~0.9 GB/s is ~2s of transfer — long enough
    # to saturate a 10G uplink while keeping each curl process at 250MB.
    local UL_CAP_MB=$((500 * STREAMS))
    if (( UL_CAP_MB > 2000 )); then UL_CAP_MB=2000; fi
    local UL_RUN_MB=$UL_MB
    if (( UL_RUN_MB > UL_CAP_MB )); then UL_RUN_MB=$UL_CAP_MB; fi

    local ul_results=()
    for i in $(seq 1 $RUNS); do
        echo -n "Upload $i/$RUNS (${UL_RUN_MB}MB x $STREAMS streams)... "
        local mbps=$(parallel_transfer upload "$((UL_RUN_MB * 1000000))" "$STREAMS")
        ul_results+=("${mbps:-0}")
        echo "${mbps:-0} Mbit/s"
    done

    # Machine-readable summary (last line, for skill to parse)
    python3 -c "
dl = [$(IFS=,; echo "${dl_results[*]}")]
ul = [$(IFS=,; echo "${ul_results[*]}")]
ping = '${ping_result}'
import re; m = re.search(r'[\d.]+/([\d.]+)/', ping); latency = m.group(1) if m else '?'
print(f'RESULT|{sum(dl)/len(dl):.0f}|{min(dl):.0f}|{max(dl):.0f}|{sum(ul)/len(ul):.0f}|{min(ul):.0f}|{max(ul):.0f}|{latency}|${DL_MB}|${RUNS}|${STREAMS}')
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

# ─── GCS Benchmark ───
#
# Design notes (potential bottlenecks considered):
#   1. File size: 20GB — large enough to amortize gcloud startup (~1-2s) at 10G speeds
#   2. Random data: incompressible — prevents GCS/transport compression cheating
#   3. Parallelism: tests both auto-tuned and aggressive (16p x 4t) to find optimum
#   4. Multi-file test: simulates real workload (many video files, not one blob)
#   5. TCP buffers: checks macOS defaults and warns if too small for 10G BDP
#   6. Local SSD: M5 Max ~7 GB/s, not a bottleneck for 10G (~1.2 GB/s)

run_gcs() {
    if ! command -v gcloud &> /dev/null; then
        warning "gcloud not installed — skipping GCS benchmark"
        return
    fi

    header "GCS Benchmark"
    local GCS_TEST_PATH="$GCS_BUCKET/$GCS_TEST_DIR"
    local REGION=$(gcloud storage buckets describe "$GCS_BUCKET" --format="value(location)" 2>/dev/null)
    echo "  Bucket: $GCS_BUCKET ($REGION)"
    echo "  File size: ${GCS_FILE_SIZE_MB}MB"
    echo "  Runs: $RUNS"

    local TESTFILE="/tmp/gcs-benchmark-$$"
    local TESTDIR="/tmp/gcs-benchmark-multi-$$"

    # Tune macOS TCP buffers for 10G
    # BDP (bandwidth-delay product) = 10 Gbps x 10ms RTT = 12.5 MB
    # TCP buffers must be >= BDP to fill the pipe. macOS defaults are often too small.
    # These reset on reboot — safe to set temporarily.
    header "TCP Buffer Tuning (for 10G)"
    local autorcv=$(sysctl -n net.inet.tcp.autorcvbufmax 2>/dev/null)
    local autosnd=$(sysctl -n net.inet.tcp.autosndbufmax 2>/dev/null)
    result "Current: send=${autosnd} recv=${autorcv} bytes"
    if [[ "$autorcv" -lt 16777216 ]]; then
        sudo sysctl -w net.inet.tcp.autorcvbufmax=16777216 >/dev/null 2>&1 \
            && sudo sysctl -w net.inet.tcp.autosndbufmax=16777216 >/dev/null 2>&1 \
            && result "Tuned: send=16MB recv=16MB (resets on reboot)" \
            || warning "Could not tune TCP buffers (needs sudo). Results may be lower than possible."
    else
        result "Already tuned (>= 16MB)"
    fi

    # Generate single large test file (random = incompressible)
    header "Generating ${GCS_FILE_SIZE_MB}MB random test file"
    openssl rand -out "$TESTFILE" $((GCS_FILE_SIZE_MB * 1048576)) 2>/dev/null \
        || dd if=/dev/urandom of="$TESTFILE" bs=1M count=$GCS_FILE_SIZE_MB 2>/dev/null
    result "Done (${GCS_FILE_SIZE_MB}MB, incompressible)"

    # Generate multi-file test set (simulates uploading video folder)
    local MULTI_FILE_COUNT=20
    local MULTI_FILE_SIZE_MB=$((GCS_FILE_SIZE_MB / MULTI_FILE_COUNT))
    header "Generating multi-file test (${MULTI_FILE_COUNT} x ${MULTI_FILE_SIZE_MB}MB)"
    mkdir -p "$TESTDIR"
    for i in $(seq 1 $MULTI_FILE_COUNT); do
        dd if=/dev/urandom of="$TESTDIR/video_$i.bin" bs=1M count=$MULTI_FILE_SIZE_MB 2>/dev/null
    done
    result "Done (${MULTI_FILE_COUNT} files, ${GCS_FILE_SIZE_MB}MB total)"

    cleanup_gcs() {
        rm -f "$TESTFILE" "$TESTFILE.down" 2>/dev/null
        rm -rf "$TESTDIR" "$TESTDIR.down" 2>/dev/null
        gcloud storage rm --recursive "$GCS_TEST_PATH/" 2>/dev/null || true
    }
    trap cleanup_gcs EXIT

    # Test 1: Single file, gcloud auto-tuned parallelism
    header "Test 1: Single File Upload — AUTO parallelism (${GCS_FILE_SIZE_MB}MB x $RUNS runs)"
    result "(gcloud auto-tunes process/thread count)"
    local ul_auto=()
    for i in $(seq 1 $RUNS); do
        local dest="$GCS_TEST_PATH/bench-auto-$i"
        start=$(python3 -c "import time; print(time.time())")
        gcloud storage cp \
            --parallel-composite-upload-threshold=50M \
            "$TESTFILE" "$dest" 2>/dev/null
        end=$(python3 -c "import time; print(time.time())")
        local speed=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB / ($end - $start):.0f}')")
        local mbps=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB * 8 / ($end - $start):.0f}')")
        ul_auto+=("$speed")
        result "Run $i: ${speed} MB/s (${mbps} Mbit/s)"
    done
    python3 -c "
r = [$(IFS=,; echo "${ul_auto[*]}")]
print(f'\033[0;32m  -> Min={min(r):.0f}  Avg={sum(r)/len(r):.0f}  Max={max(r):.0f} MB/s\033[0m')
"

    # Test 2: Single file, aggressive parallelism (16 processes x 4 threads)
    header "Test 2: Single File Upload — AGGRESSIVE (16p x 4t, ${GCS_FILE_SIZE_MB}MB x $RUNS runs)"
    local ul_agg=()
    for i in $(seq 1 $RUNS); do
        local dest="$GCS_TEST_PATH/bench-agg-$i"
        start=$(python3 -c "import time; print(time.time())")
        gcloud storage cp \
            --parallel-composite-upload-threshold=50M \
            --process-count=16 \
            --thread-count=4 \
            "$TESTFILE" "$dest" 2>/dev/null
        end=$(python3 -c "import time; print(time.time())")
        local speed=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB / ($end - $start):.0f}')")
        local mbps=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB * 8 / ($end - $start):.0f}')")
        ul_agg+=("$speed")
        result "Run $i: ${speed} MB/s (${mbps} Mbit/s)"
    done
    python3 -c "
r = [$(IFS=,; echo "${ul_agg[*]}")]
print(f'\033[0;32m  -> Min={min(r):.0f}  Avg={sum(r)/len(r):.0f}  Max={max(r):.0f} MB/s\033[0m')
"

    # Test 3: Multi-file upload (real workload: many files concurrently)
    header "Test 3: Multi-File Upload — ${MULTI_FILE_COUNT} files (${GCS_FILE_SIZE_MB}MB total, $RUNS runs)"
    result "(simulates uploading a folder of video files)"
    local ul_multi=()
    for i in $(seq 1 $RUNS); do
        local dest="$GCS_TEST_PATH/bench-multi-$i/"
        start=$(python3 -c "import time; print(time.time())")
        gcloud storage cp --recursive \
            --parallel-composite-upload-threshold=50M \
            --process-count=16 \
            --thread-count=4 \
            "$TESTDIR/" "$dest" 2>/dev/null
        end=$(python3 -c "import time; print(time.time())")
        local speed=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB / ($end - $start):.0f}')")
        local mbps=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB * 8 / ($end - $start):.0f}')")
        ul_multi+=("$speed")
        result "Run $i: ${speed} MB/s (${mbps} Mbit/s)"
    done
    python3 -c "
r = [$(IFS=,; echo "${ul_multi[*]}")]
print(f'\033[0;32m  -> Min={min(r):.0f}  Avg={sum(r)/len(r):.0f}  Max={max(r):.0f} MB/s\033[0m')
"

    # Test 4: Download (single large file)
    header "Test 4: Single File Download (${GCS_FILE_SIZE_MB}MB x $RUNS runs)"
    local dl_results=()
    local src="$GCS_TEST_PATH/bench-auto-1"
    for i in $(seq 1 $RUNS); do
        rm -f "$TESTFILE.down" 2>/dev/null
        start=$(python3 -c "import time; print(time.time())")
        gcloud storage cp \
            --process-count=16 \
            --thread-count=4 \
            "$src" "$TESTFILE.down" 2>/dev/null
        end=$(python3 -c "import time; print(time.time())")
        local speed=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB / ($end - $start):.0f}')")
        local mbps=$(python3 -c "print(f'{$GCS_FILE_SIZE_MB * 8 / ($end - $start):.0f}')")
        dl_results+=("$speed")
        result "Run $i: ${speed} MB/s (${mbps} Mbit/s)"
        rm -f "$TESTFILE.down" 2>/dev/null
    done

    python3 -c "
r = [$(IFS=,; echo "${dl_results[*]}")]
print(f'\033[0;32m  -> Min={min(r):.0f}  Avg={sum(r)/len(r):.0f}  Max={max(r):.0f} MB/s\033[0m')
"

    # Summary
    header "GCS Summary"
    python3 -c "
auto = [$(IFS=,; echo "${ul_auto[*]}")]
agg = [$(IFS=,; echo "${ul_agg[*]}")]
multi = [$(IFS=,; echo "${ul_multi[*]}")]
dl = [$(IFS=,; echo "${dl_results[*]}")]
print(f'\033[0;32m  Upload (auto):       {sum(auto)/len(auto):.0f} MB/s avg = {sum(auto)/len(auto)*8:.0f} Mbit/s\033[0m')
print(f'\033[0;32m  Upload (aggressive): {sum(agg)/len(agg):.0f} MB/s avg = {sum(agg)/len(agg)*8:.0f} Mbit/s\033[0m')
print(f'\033[0;32m  Upload (multi-file): {sum(multi)/len(multi):.0f} MB/s avg = {sum(multi)/len(multi)*8:.0f} Mbit/s\033[0m')
print(f'\033[0;32m  Download:            {sum(dl)/len(dl):.0f} MB/s avg = {sum(dl)/len(dl)*8:.0f} Mbit/s\033[0m')
print()
best_ul = max(sum(auto)/len(auto), sum(agg)/len(agg), sum(multi)/len(multi))
print(f'\033[0;32m  Best upload: {best_ul:.0f} MB/s ({best_ul*8:.0f} Mbit/s) = {best_ul*8/10000*100:.0f}% of 10G line\033[0m')
print(f'\033[0;32m  Download:    {sum(dl)/len(dl):.0f} MB/s ({sum(dl)/len(dl)*8:.0f} Mbit/s) = {sum(dl)/len(dl)*8/10000*100:.0f}% of 10G line\033[0m')
"

    # Cleanup
    header "Cleanup"
    gcloud storage rm --recursive "$GCS_TEST_PATH/" 2>/dev/null
    rm -f "$TESTFILE" "$TESTFILE.down" 2>/dev/null
    rm -rf "$TESTDIR" "$TESTDIR.down" 2>/dev/null
    trap - EXIT
    result "Done"
}

# ─── Main ───

print_header
echo ""

case "$MODE" in
    internet) run_internet ;;
    nas)      run_nas ;;
    gcs)      run_gcs ;;
    all)      run_internet; run_nas; run_gcs ;;
    *)        echo "Usage: $0 [all|internet|nas|gcs] [runs]"; exit 1 ;;
esac

echo "Benchmark complete."

#!/bin/bash
# OUI Lookup — resolve MAC address prefixes to vendor names
# Usage:
#   source scripts/oui-lookup.sh
#   oui_lookup "48:ed:e6"  → "Zyxel Communications Corporation"
#
# Lookup order: mac-vendors.txt (local cache) → IEEE oui.txt → macvendors.com API → unknown
# IEEE file: ~/.local/share/oui.txt (auto-downloaded, refreshed monthly on ≥1G links)

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
OUI_FILE="$HOME/.local/share/oui.txt"
MAC_VENDORS_FILE="$DOTFILES/docs/device-names.txt"
USB_DEVICES_FILE="$DOTFILES/docs/usb-devices.txt"

# Ensure mac-vendors.txt exists
[[ -f "$MAC_VENDORS_FILE" ]] || touch "$MAC_VENDORS_FILE"

# Download/refresh IEEE OUI file if needed
oui_ensure_fresh() {
    mkdir -p "$(dirname "$OUI_FILE")"

    local need_download=false
    if [[ ! -f "$OUI_FILE" ]]; then
        need_download=true
    else
        # Check if older than 30 days
        local file_mod
        file_mod=$(stat -f %m "$OUI_FILE" 2>/dev/null) || file_mod=0
        local file_age=$(( ($(date +%s) - file_mod) / 86400 ))
        if [[ "$file_age" -gt 30 ]]; then
            # Only re-download on ≥1G links
            local media=$(ifconfig "$(route get 8.8.8.8 2>/dev/null | grep interface | awk '{print $2}')" 2>/dev/null | grep media | head -1)
            if echo "$media" | grep -q "1000baseT\|2500baseT\|5000baseT\|10GbaseT\|10Gbase"; then
                need_download=true
            fi
        fi
    fi

    if [[ "$need_download" == "true" ]]; then
        curl -s -o "$OUI_FILE.tmp" "https://standards-oui.ieee.org/oui/oui.txt" 2>/dev/null
        if [[ -s "$OUI_FILE.tmp" ]]; then
            mv "$OUI_FILE.tmp" "$OUI_FILE"
        else
            rm -f "$OUI_FILE.tmp"
        fi
    fi
}

# Look up a MAC prefix (e.g., "48:ed:e6" or "48:ED:E6")
# Returns: vendor name or "unknown"
oui_lookup() {
    local mac_prefix="$1"
    # Normalize: uppercase, remove colons/dashes
    local normalized=$(echo "$mac_prefix" | tr '[:lower:]' '[:upper:]' | tr -d ':' | tr -d '-' | head -c 6)

    # 1. Check local cache (mac-vendors.txt)
    if [[ -f "$MAC_VENDORS_FILE" ]]; then
        local cached=$(grep -i "^${mac_prefix}" "$MAC_VENDORS_FILE" 2>/dev/null | head -1 | sed 's/^[^ ]* //')
        if [[ -n "$cached" ]]; then
            echo "$cached"
            return 0
        fi
    fi

    # 2. Check IEEE OUI file
    oui_ensure_fresh
    if [[ -f "$OUI_FILE" ]]; then
        local ieee=$(grep -i "^  ${normalized}" "$OUI_FILE" 2>/dev/null | head -1 | sed 's/.*)\s*//' | xargs)
        if [[ -n "$ieee" ]]; then
            echo "$ieee"
            return 0
        fi
    fi

    # 3. Try API (with short timeout)
    local api_result=$(curl -s --max-time 3 "https://api.macvendors.com/${mac_prefix}" 2>/dev/null)
    if [[ -n "$api_result" && ! "$api_result" =~ "error" && ! "$api_result" =~ "Not Found" ]]; then
        echo "$api_result"
        return 0
    fi

    echo "unknown"
    return 1
}

# Save a friendly name to mac-vendors.txt
oui_cache_save() {
    local mac_prefix="$1"
    local friendly_name="$2"
    # Remove existing entry if present
    if [[ -f "$MAC_VENDORS_FILE" ]]; then
        grep -iv "^${mac_prefix}" "$MAC_VENDORS_FILE" > "$MAC_VENDORS_FILE.tmp" 2>/dev/null || true
        mv "$MAC_VENDORS_FILE.tmp" "$MAC_VENDORS_FILE"
    fi
    echo "${mac_prefix} ${friendly_name}" >> "$MAC_VENDORS_FILE"
    sort -o "$MAC_VENDORS_FILE" "$MAC_VENDORS_FILE"
}

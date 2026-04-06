# Repo Review — 2026-04-06

## Summary

The repo is in good shape. Both previous findings from 2026-04-04 are resolved. This review found one CRITICAL bug (broken file paths in `oui-lookup.sh` that silently defeat local lookups), one MODERATE ghost file, and two LOW documentation gaps introduced today when networking tools were added.

**Findings: 1 CRITICAL, 1 MODERATE, 2 LOW**

---

## Previous Review Status

Both items from `docs/repo-review-2026-04-04.md` resolved:

| # | Issue | Status |
|---|-------|--------|
| 1 | Uncommitted `configs/claude/settings.json` | Fixed — committed in `e14af83` |
| 2 | SERVERS.md dl-coder Node version snapshot stale | Fixed — line 29 now says `Node.js 22` |

---

## Findings

### CRITICAL

#### 1. `oui-lookup.sh` references wrong paths for device data files

- **Location:** `scripts/oui-lookup.sh` lines 12–13
- **Evidence:** The script sets:
  ```bash
  MAC_VENDORS_FILE="$DOTFILES/device-names.txt"
  USB_DEVICES_FILE="$DOTFILES/usb-devices.txt"
  ```
  Both files were moved to `docs/` in commit `49c4cd4`. `$DOTFILES/usb-devices.txt` does not exist at all. `$DOTFILES/device-names.txt` exists but is **empty** (a ghost file re-added in `967b636`). As a result:
  - `oui_lookup()` always misses the local cache and falls through to the IEEE OUI file or API.
  - `oui_cache_save()` writes to the empty root file rather than `docs/device-names.txt`, so saved entries are never found again.
  - The two entries in `docs/device-names.txt` (ZyXEL EX3600-T0, Kalea 10G USB-C) are invisible to the script.
- **Impact:** OUI lookups silently fall back to slower IEEE/API lookups every time, and any newly saved device names accumulate in the wrong file.
- **Recommendation:** Update `oui-lookup.sh` lines 12–13:
  ```bash
  MAC_VENDORS_FILE="$DOTFILES/docs/device-names.txt"
  USB_DEVICES_FILE="$DOTFILES/docs/usb-devices.txt"
  ```

---

### MODERATE

#### 2. Empty ghost file `device-names.txt` at repo root

- **Location:** `device-names.txt` (repo root)
- **Evidence:** File is tracked by git, completely empty (0 bytes), and was re-added in commit `967b636` after the canonical version was moved to `docs/device-names.txt` in `49c4cd4`. The root copy serves no purpose and actively misleads `oui-lookup.sh` (see Finding 1).
- **Impact:** Confusing to anyone reading the repo — two `device-names.txt` files exist, one empty. The `oui-lookup.sh` bug (Finding 1) is partly caused by this ghost.
- **Recommendation:** Delete `device-names.txt` from the repo root (`git rm device-names.txt`). After fixing Finding 1, the root path will no longer be referenced.

---

### LOW

#### 3. Networking tools added to `install.sh` but not listed in README

- **Location:** `install.sh` line 30, `README.md` Dev Tools section
- **Evidence:** `nmap`, `mtr`, `iperf3`, `jq`, and `doggo` were added to `install.sh` today. The README Dev Tools table does not mention them. A reader scanning the README for what's installed wouldn't know they're included.
- **Impact:** Cosmetic — README undersells the toolset.
- **Recommendation:** Add a "Networking Tools" row or section to the README Dev Tools table.

#### 4. Two previous repo-review files accumulating in `docs/`

- **Location:** `docs/repo-review-2026-04-03.md`, `docs/repo-review-2026-04-04.md`
- **Evidence:** Each review adds a new file. No cleanup policy defined. With this review, there will be three.
- **Impact:** Low — docs/ grows slowly. But the old reviews are fully superseded; they document only resolved findings.
- **Recommendation:** Either keep only the latest review (delete prior ones), or document the "keep all" intent so it's clearly intentional.

---

## Recommendations

### Quick wins (< 5 min)
1. Fix `oui-lookup.sh` paths (Finding 1): change `$DOTFILES/device-names.txt` → `$DOTFILES/docs/device-names.txt` and `$DOTFILES/usb-devices.txt` → `$DOTFILES/docs/usb-devices.txt`
2. Delete root `device-names.txt` (Finding 2): `git rm device-names.txt`

### Low effort (< 15 min)
3. Add networking tools to README Dev Tools section (Finding 3)
4. Decide on repo-review file retention policy (Finding 4)

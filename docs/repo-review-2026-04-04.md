# Repo Review — 2026-04-04

## Summary

The repo is in excellent shape. All 20 findings from the 2026-04-03 review were addressed in commit `49c4cd4`. This review found only 2 new issues: one uncommitted config change and one stale version number in SERVERS.md.

**Findings: 0 CRITICAL, 1 MODERATE, 1 LOW**

---

## Previous Review Status

All items from `docs/repo-review-2026-04-03.md` resolved:

| # | Issue | Status |
|---|-------|--------|
| 1 | `update.sh` referenced in README | Fixed — references removed |
| 2 | dl-content-host machine type contradictions | Fixed — SERVERS.md is authoritative (e2-small, 2 GB) |
| 3 | dl-coder docs said "No Node" | Fixed — SERVERS.md now lists Node.js 22 |
| 4 | karabiner not in install.sh | Fixed — cask + symlink added |
| 5 | mosh not installed | Fixed — added to brew install |
| 6 | ask-anthropic not installed | Fixed — `go install` added to install.sh |
| 7 | setup.sh superseded by install.sh | Fixed — setup.sh deleted |
| 8 | check.sh drifted from install.sh | Fixed — ssh_config, karabiner, claude files, vscode all now checked |
| 9 | Duplicate `ll` alias | Fixed — dead alias removed |
| 10 | NETWORK_HOME.md ISP speed contradiction | Fixed — diagram now says 10G/10G |
| 11 | README file tree stale | Fixed — scripts/, docs/, check.sh, LOCAL_LLM.md added |
| 12 | CLAUDE.md tree stale | Fixed — updated |
| 13 | NordVPN undocumented | Fixed — M1_MAC.md documents China travel use case |
| 14 | 8 apps missing from README | Fixed — all added |
| 15 | 5 stale apps in README | Fixed — removed |
| 16 | Stockfish comment confusing | Fixed — comment clarifies CLI (brew) vs GUI (App Store) |
| 17 | linkedin_dma_access_token missing from SETUP_CHECKLIST | Fixed |
| 18 | starship.toml dead [time]/[username] sections | Fixed — both have `disabled = true` |
| 19 | LOCAL_LLM.md untracked | Fixed — committed |
| 20 | nvim options.lua uncommitted | Fixed — committed in 49c4cd4 |

---

## Findings

### CRITICAL

None.

---

### MODERATE

#### 1. Uncommitted `configs/claude/settings.json`

- **Location:** `configs/claude/settings.json`
- **Evidence:** `git status` shows the file modified. Diff:
  - `effortLevel`: `"high"` → `"medium"`
  - `model`: `"sonnet"` added (new key)
- **Impact:** Active Claude Code config diverges from what's tracked. A fresh machine setup from the repo would use different settings than the current machine.
- **Recommendation:** Commit the change.

---

### LOW

#### 2. SERVERS.md dl-coder Node version snapshot is stale

- **Location:** `docs/SERVERS.md` line 29
- **Evidence:** The "Installed Software" table shows `Node v18.20.4` (the version at initial setup). Line 76 in the same file correctly states `Node.js 22 (installed for Claude Code)`. These two references conflict.
- **Impact:** Cosmetic confusion — the authoritative note is already there at line 76.
- **Recommendation:** Update line 29's software table entry to `Node.js 22` or remove the version pin from the snapshot.

---

## Recommendations

### Quick wins (< 5 min)
1. Commit `configs/claude/settings.json`
2. Update SERVERS.md dl-coder Node version in the software table (line 29)

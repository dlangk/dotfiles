# Repo Review — 2026-04-03

## Summary

Dotfiles repo is in good shape overall — no critical security issues, no generated artifacts tracked, no abandoned experimental directories. The main systemic issue is **docs-to-code drift**: install.sh has evolved faster than README.md and SERVERS.md. There are also a few tools referenced in configs that install.sh doesn't install, meaning a fresh machine setup would be incomplete.

**Findings: 3 CRITICAL, 7 MODERATE, 10 LOW**

---

## Findings

### CRITICAL

#### 1. `update.sh` referenced in README but does not exist
- **Location:** `README.md` lines ~128, 183-186
- **Evidence:** README lists `update.sh` in the file tree and documents its usage (`./update.sh --check`, `./update.sh`), but no such file exists. The `/maintain` skill likely replaced it.
- **Recommendation:** Remove `update.sh` references from README.

#### 2. dl-content-host machine type contradicts between files
- **Location:** `SERVERS.md` says **e2-small (2 vCPU, 2 GB)**. `servers/dl-content-host/install.sh` and `setup.sh` say **e2-micro**. MEMORY.md says **e2-micro, 1GB RAM**.
- **Recommendation:** Update install script comments and MEMORY.md to match SERVERS.md (e2-small, 2 GB).

#### 3. dl-coder SERVERS.md says "No Node" but install.sh installs Node + Claude Code
- **Location:** `SERVERS.md`: "No Docker, Nginx, Node, Go, or Java". `servers/dl-coder/install.sh` installs Node.js 22 and Claude Code via npm.
- **Recommendation:** Update SERVERS.md dl-coder section to list Node.js.

---

### MODERATE

#### 4. `karabiner/` not symlinked by install.sh, cask not installed
- **Location:** `karabiner/karabiner.json` exists but install.sh has no symlink and no `karabiner-elements` cask.
- **Evidence:** Both README.md and CLAUDE.md claim the symlink exists.
- **Recommendation:** Add cask and symlink to install.sh, or remove karabiner/ from repo.

#### 5. `mosh` not installed by install.sh but used via alias
- **Location:** `zshrc` references `mosh-coder` alias. install.sh doesn't install mosh.
- **Recommendation:** Add `mosh` to brew install line.

#### 6. `ask-anthropic` Go tool referenced but not installed
- **Location:** `zshrc` line 71: `alias ask="ask-anthropic"` with comment about `go install`.
- **Recommendation:** Add `go install github.com/dlangk/ask-anthropic@latest` to install.sh.

#### 7. `servers/dl-content-host/setup.sh` superseded by `install.sh`
- **Location:** Both scripts do the same things. `install.sh` is a superset.
- **Recommendation:** Delete `setup.sh`, update README.

#### 8. `check.sh` drifted from install.sh
- **Location:** check.sh doesn't verify ssh_config or individual claude file symlinks. Checks claude as a directory symlink, but install.sh symlinks individual files.
- **Recommendation:** Align check.sh with install.sh.

#### 9. `ll` alias defined twice in zshrc
- **Location:** Line ~143: `alias ll="ls -lah"`, then line ~151: `alias ll="eza --icons --git -lah"`.
- **Evidence:** Second silently overrides first. First is dead code.
- **Recommendation:** Remove the first `ll` alias.

#### 10. NETWORK_HOME.md ISP speed contradiction
- **Location:** Body says "10G/10G symmetric fiber" but diagram says "1000/1000 Mbps".
- **Recommendation:** Update diagram label to 10G/10G.

---

### LOW

#### 11. README file tree is stale
- Shows `setup.sh` for both servers (dl-coder only has `install.sh`).
- Missing: `scripts/`, `docs/`, `device-names.txt`, `usb-devices.txt`, `check.sh`, `LOCAL_LLM.md`.
- **Recommendation:** Update tree.

#### 12. CLAUDE.md directory tree is stale
- Missing: `scripts/`, `docs/`, `check.sh`, `LOCAL_LLM.md`. Claims karabiner is symlinked (it isn't).
- **Recommendation:** Update tree.

#### 13. NordVPN in install.sh but never documented
- install.sh installs `nordvpn` cask. M1_MAC.md only documents Mullvad.
- **Recommendation:** Document why both VPNs are needed, or remove one.

#### 14. 8 apps in install.sh not in README
- `audacity`, `reaper`, `wireshark-app`, `typefully`, `godot`, `wispr-flow`, `openmtp`, `claude-code`
- **Recommendation:** Add to README Applications table.

#### 15. 5 apps in README not in install.sh
- `Clocker`, `Xnapper`, `Stats`, `Webex`, `iA Writer`
- **Recommendation:** Remove from README if no longer used.

#### 16. Stockfish installed twice (brew CLI + App Store note)
- Confusing comment. Brew installs the engine, App Store is presumably for GUI.
- **Recommendation:** Clarify the comment.

#### 17. `linkedin_dma_access_token` in zshrc but not in install.sh or SETUP_CHECKLIST
- **Recommendation:** Add to SETUP_CHECKLIST.md under API Keys.

#### 18. starship.toml has dead `[time]` and `[username]` sections
- Both configured but not in the format string, so they don't render. CLAUDE.md says "no time, no username".
- **Recommendation:** Set `disabled = true` or remove dead sections.

#### 19. Untracked `LOCAL_LLM.md`
- 132 lines, created today. Not staged, not in .gitignore.
- **Recommendation:** Commit it.

#### 20. Uncommitted nvim options change
- `nvim/lua/config/options.lua` has local changes (wrap + linebreak).
- **Recommendation:** Commit or revert.

---

## Recommendations

### Quick wins (< 5 min each)
1. Delete `servers/dl-content-host/setup.sh`
2. Remove dead `ll` alias (line ~143 of zshrc)
3. Add `mosh` to brew install line
4. Remove `update.sh` references from README
5. Commit `LOCAL_LLM.md` and nvim options change
6. Add `.DS_Store` to `.gitignore`

### Medium effort (15-30 min)
7. Update README.md file tree and Applications table
8. Update CLAUDE.md directory tree
9. Align check.sh with install.sh (symlink checks)
10. Update SERVERS.md for dl-coder (Node.js) and dl-content-host (e2-small)
11. Add karabiner symlink + cask to install.sh
12. Add `ask-anthropic` go install to install.sh

### Clarification needed from user
13. Is Tailscale still used on Mac? (Referenced in 5+ places, removed from servers)
14. Is NordVPN still needed alongside Mullvad?
15. Are `claude/commands/*.md` still used or replaced by skills system?
16. Keep or gitignore `nvim/lazy-lock.json`?

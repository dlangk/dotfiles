---
name: collector-local
description: Run the Mac-ONLY langkilde-collector extractors (blog, dotfiles, mac-messages) on the laptop. Server-owned sources (gmail, docs, notion, slack, calendar, contacts, tasks, finance) are NEVER re-collected locally — they are already harvested on the server; use /collector-get to mirror them down. Verbs:`sync` (default), `status`. Targets:`all` (default — blog + dotfiles), `blog`, `dotfiles`, `mac-messages`. Triggers on sync collector, update collector, sync corpus, update corpus, run extractors, pull new content, sync imessage, sync whatsapp, upload messages, sync locally.
---

# /collector-local

Runs the **Mac-only** extractors for the langkilde-collector repo — the ones
that read paths that exist only on this laptop. Nothing else.

```
CORPUS=/Users/langkilde/dev/personal-tools/langkilde-collector
```

## The rule (2026-09-11)

**Local sync must never redo work the server already does.** The GCP box
(`langkilde-se`) harvests Gmail, Google Docs/Sheets/Slides/PDFs/Excel,
Calendar, Contacts, Tasks, Notion, and Kognic finance four times a day, and
runs the always-on Slack daemon. The server's `collector.db` is authoritative;
the Mac's copy is a **read-only mirror** that the next pull overwrites.

Running those extractors on the Mac therefore burns 30+ minutes of API calls
(Slack alone is ~55 min for a full pass), writes into a copy that gets
clobbered, and gains nothing. So:

| Source | Where it is collected | How to get it on the Mac |
|---|---|---|
| gmail, docs, notion, slack, calendar, contacts, tasks, finance | server | `/collector-get` (or `collector-control get --pull-only` for a fast mirror without a fresh collect) |
| blog, dotfiles | Mac | this skill |
| mac-messages (iMessage / WhatsApp / calls / Messenger) | Mac | this skill, explicit target |

If the user asks this skill for `gmail`, `docs`, `notion`, `slack`, or any
other server-owned source: **do not run it.** Reply with one line saying it is
server-collected and run `/collector-get` instead (ask first only if they
explicitly said not to pull). There is no `--force` escape hatch; if they
truly need a local run of a server extractor they can invoke
`uv run extractors/<name>.py` themselves.

## Invocation

```
/collector-local [verb] [target...] [--flag...]
```

**Verbs** (default: `sync`):

| Verb | Side effects |
|---|---|
| `sync` | writes to `$CORPUS/blog/`, `$CORPUS/setup/`, and (mac-messages only) `collector-messages.db` |
| `status` | none — reports last-run state |

**Targets** (default: `all`):

| Target | Extractor(s) |
|---|---|
| `all` | `dotfiles.py` + `blog.py` (**not** mac-messages — see below) |
| `blog` | `blog.py` |
| `dotfiles` | `dotfiles.py` |
| `mac-messages` | `mac_local.py` + `deploy/mac/push-messages-db.sh` — explicit only |

See `~/.claude/skills/CONVENTIONS.md` for universal flags (`--dry-run`, `--verbose`, etc.).

---

## `sync`

Runs from `$CORPUS` using `uv run`.

### `all` target

```bash
cd $CORPUS
uv run extractors/dotfiles.py
uv run extractors/blog.py
```

Both finish in seconds. After they run, remind the user that server-collected
data is mirrored with `/collector-get`, and mention when the local mirror was
last pulled (first line of `$CORPUS/LAST_SYNC.md`).

### `blog` caveats

`blog.py` reads the website source at the `SOURCE` path in
`extractors/blog.py`. If that directory does not exist (as of 2026-09-11 the
old `~/dev/public/langkilde/src/content/short` checkout is gone from this
Mac), report **SKIP: blog source checkout missing at <path>** and move on.
Do not retry, do not guess another path — the fix is to clone the site repo or
update `SOURCE`.

### `mac-messages` target

Different shape from the other targets: reads SIP-protected local files (needs
Full Disk Access granted to the terminal in System Settings → Privacy &
Security), writes to a **separate** `collector-messages.db` (not
`collector.db`), and requires an explicit push step to reach the server/GCS.
This is why it's excluded from `all`. CLAUDE.md documents
`collector-messages.db` as the *only* durable copy of this data, so treat push
failures as worth surfacing clearly.

```bash
uv run extractors/mac_local.py --only imessage whatsapp   # iMessage + WhatsApp only
uv run extractors/mac_local.py                            # + calls + Messenger
./deploy/mac/push-messages-db.sh                           # scp collector-messages.db to the server
```

If the first command fails immediately with a permissions/access error, it's
almost certainly missing Full Disk Access — report that plainly rather than
retrying.

### Pre-flight checks

1. **Corpus repo exists** — `ls $CORPUS/update.sh` or exit with a clear error
2. **uv available** — `which uv`
3. **blog source** (blog target only) — the `SOURCE` dir in `extractors/blog.py` exists
4. **dotfiles docs** (dotfiles target only) — `ls ~/dotfiles/docs`

If a check fails, report it and skip that extractor; don't abort the run.

---

## `status`

Read-only.

```bash
cd $CORPUS
head -3 LAST_SYNC.md                      # when the server mirror was last pulled
ls -lt setup/ | head -3                   # dotfiles: newest synced doc
ls -lt blog/ | head -3                    # blog: newest synced post
launchctl list | grep collector-pull      # is the twice-daily pull job loaded?
```

Report the mirror age from `LAST_SYNC.md`; if it is more than a day old,
suggest `/collector-get`.

---

## Output

```
Local sync: 1 OK, 1 SKIPPED, 0 FAILED

| Extractor | Status  | Notes |
|-----------|---------|-------|
| dotfiles  | OK      | 10 files in setup/ |
| blog      | SKIPPED | source checkout missing at ~/dev/public/langkilde/src/content/short |

Server-collected data (gmail/docs/notion/slack/…) last mirrored: 2026-09-11 16:40 CEST — run /collector-get to refresh.
```

Use **SKIP** for pre-flight failures, **WARN** for non-fatal errors, **FAIL** for hard errors.

With `--dry-run`, output the commands instead of running them.
With `--quiet`, show only line 1 + the count summary.

---

## LinkedIn reminder

LinkedIn sync requires a manual GDPR export. If the user asks about stale LinkedIn data:

> Request a GDPR export at linkedin.com → Me → Settings & Privacy → Data privacy → Get a copy of your data. Select Posts and Messages. Then run: `uv run extractors/linkedin.py path/to/LinkedIn_export.zip`

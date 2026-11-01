---
name: collector-get
description: Get a fresh full local copy of the langkilde-collector corpus. Collects fresh on the server (langkilde-se), then mirrors the ENTIRE corpus (Gmail, Google Docs/Sheets/Slides, Notion incl. meeting transcripts, slack-dumps) + collector.db from GCS to the Mac, and writes a LAST_SYNC.md freshness manifest. Triggers on get everything, get the latest data, get a fresh copy, get a fresh copy of the data, pull everything locally, mirror the collector locally, refresh my local collector data, download all the collector data.
---

# /collector-get

"Get everything." Runs a fresh server collect, then mirrors the complete
server-collected corpus + `collector.db` down to the Mac and writes a freshness
manifest. Wraps the `get` verb of the `collector-control` script.

Script: `~/dev/personal-tools/langkilde-collector/collector-control`

## Invocation

Default — collect fresh on the server, then mirror everything:

```bash
~/dev/personal-tools/langkilde-collector/collector-control get
```

Just mirror the current GCS state without re-collecting (fast):

```bash
~/dev/personal-tools/langkilde-collector/collector-control get --pull-only
```

## What it does

1. Triggers a fresh server collect (`collector-collect.service` → `collect.py`
   + `backup.sh` → GCS). Blocks until it finishes. Slack stays current in
   parallel via the always-on `collector-slack-daemon`.
2. Runs `deploy/mac/pull-all.sh`, which:
   - **mirrors** the server-generated dirs from GCS (`gmail-*`,
     `google-docs/sheets/slides-*`, `notion-kognic`, `slack-dumps`),
   - **add-only** copies the human/Mac-authored dirs (`--no-clobber`, never
     overwrites local edits): `blog`, `ceo-reports`, `emails`, `linkedin`,
     `questionnaire`, `setup`, `slack`,
   - pulls `collector.db` via the integrity-checked atomic swap
     (`pull-collector-db.sh`),
   - writes `LAST_SYNC.md` at the repo root — a table of each dataset's newest
     item + row count, so it's obvious when everything was last published.

## Not touched

- `docs/` — version-controlled repo source, not corpus data.
- `collector-messages.db` — Mac-authoritative (iMessage/WhatsApp/calls); the
  Mac's copy is newer than the server's, so it's never pulled.

## Related skills

- `collector-cloud` — operate the server (status/health/logs/run/tail/reauth).
- `collector-local` — run the extractors locally on the Mac (the alternative to
  mirroring the server's already-collected data).

## Notes

- First run is large (~GBs, both full Gmail trees). Subsequent runs are delta
  (`gcloud rsync` only transfers changed files).
- Reads `LAST_SYNC.md` after a run to report freshness back to the user.

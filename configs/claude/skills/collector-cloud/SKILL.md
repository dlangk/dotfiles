---
name: collector-cloud
description: Operate the langkilde-collector server deploy (langkilde-se). Verbs — status (default), health, logs, run, tail, reauth. Triggers on collector status, check the collector server, collector logs, run the collector, reauth collector tokens, collector health.
---

# /collector-cloud

Wraps the `collector-control` script in the langkilde-collector repo, which
SSHes into `langkilde-se` and reads the collector's status/health/journal.

Script: `~/dev/personal-tools/langkilde-collector/collector-control`

## Invocation

Run the script with the requested verb (default `status`):

```bash
~/dev/personal-tools/langkilde-collector/collector-control <verb> [args]
```

| Verb | Use |
|---|---|
| `status` | per-step `.collect-status.json` + token `.health-status.json` + next timer fire + last GCS backup |
| `health` | run the four-token probe now (kognic/personal/notion/slack) |
| `logs [N]` | journal tail (default 60); `logs --failures` greps errors |
| `run [--only X]` | trigger a run via systemd; `--foreground` streams collect.py |
| `tail` | follow an in-progress run |
| `reauth [account]` | mint Google token locally (browser) + scp up; or push a new notion/slack token |

## Notes
- Server access + reauth's browser step run from the Mac. The box rejects
  `gcloud compute ssh`; the script uses `ssh -i ~/.ssh/id_ed25519 daniel.langkilde@…`.
- If `health` reports a STALE token, run `collector-control reauth <account>`.

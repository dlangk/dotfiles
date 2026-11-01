# Skill Conventions

Every skill in this repo follows the same grammar so that learning one skill teaches the shape of all of them. Inspired by unix CLIs (`git`, `kubectl`, `apt`, `brew`).

## Naming

1. **Skill name is the subject — a single lowercase noun.** Never a verb. Never hyphenated.
   - `mac`, `cloud`, `network`, `repo`, `corpus`, `rolodex` ✓
   - `sync-corpus`, `mac-health-check`, `repo-review`, `maintain` ✗
2. **What you *do* to the subject is the subcommand** (`/corpus sync`, not `/sync-corpus`).
3. If a skill is one-shot and has no meaningful verbs, omit the subcommand — the bare skill name acts as the default verb.

## Invocation grammar

```
/<noun> [verb] [target...] [--flag...]
```

- **`<verb>`** — what to do. Drawn from the shared vocabulary below.
- **`[target...]`** — what to do it to. Skill-specific. `all` is reserved and means "every target this skill knows about."
- **`--flag`** — modifiers. Universal flags are the same in every skill (see below).

## Shared verb vocabulary

Skills add domain-specific verbs only when nothing here fits.

| Verb | Means | Side effects | Notes |
|---|---|---|---|
| `status` | Show current state — fast read | none | Default when verb is omitted. Cheap; meant to be run often. |
| `audit` | Deep inspection, slower than `status` | none | Used for security/health audits, repo decay scans. |
| `test` | Active probing — sends traffic, hits external APIs | none persistent | Network speed tests, latency checks. |
| `sync` | Pull external state into a local store | writes local cache/db | One-way: remote → local. |
| `update` | Upgrade installed software | mutates system | OS packages, language toolchains, app updates. |
| `apply` | Apply local config to a remote target | mutates target | Provisioning, deployment, settings sync. |

Skills MAY add their own verbs (`rolodex catchup`, `rolodex note`) when the operation genuinely doesn't fit one of the above. New verbs should be a single English word in imperative form.

## Universal flags

Every skill supports these. Skill-specific flags may be added on top.

| Flag | Long form | Meaning |
|---|---|---|
| `-h` | `--help` | Print usage and exit |
| `-v` | `--verbose` | Show full per-target output |
| `-q` | `--quiet` | Print only the summary line and any failures |
| `-n` | `--dry-run` | Show what would happen without doing it. Never mutates, even with `--yes`. |
| `-y` | `--yes` | Skip confirmation prompts for irreversible actions |

## Safety rules

1. **Verbs that mutate** prompt before any **irreversible** operation (reboot, force-pull, mass delete) unless `--yes` is set.
2. **`--dry-run` never mutates**, even if `--yes` is also passed.
3. A failure on one target doesn't abort the others — collect and report at the end.
4. `status` and `audit` are read-only contracts. A skill that violates them is broken.

## Output contract

Every skill's output follows the same three-part shape so users can scan many invocations quickly.

```
<one-line summary>

## <target 1>
<details>

## <target 2>
<details>

<count summary line>
```

- **Line 1** — one-sentence summary (`Mac healthy; 2 brew packages outdated`).
- **Body** — per-target sections, each starting with `## <target>` so they're greppable. Skills with one target may collapse the body into a single section without a header.
- **Last line** — counts (`3 targets OK, 1 needs reboot, 0 errors`).

`--quiet` collapses the body, keeping only line 1 and the last line.
`--verbose` keeps everything and adds command transcripts where useful.

## Frontmatter description

Each skill's `description:` frontmatter MUST end with a verb list, like:

> ...Verbs: `status` (default), `audit`, `update`, `power`. Triggers on...

This makes the dispatcher's job easier and keeps the contract visible at the top of the file.

## When to break these rules

Don't, unless there's a specific reason worth documenting in the SKILL.md itself. The point of the convention is consistency.

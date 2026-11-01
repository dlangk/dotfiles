---
name: rolodex
description: Personal contacts CLI + interaction data — sync, catch-up, notes, tags, edit contact details, export KB, and reverse-lookup/diagnose contacts. Verbs:`sync` (default — pull contacts + 5 interaction channels), `status`, `catchup`, `note`, `tag`, `untag`, `tags`, `sync-groups`, `profile`, `pull-profiles`, `kb-export`. Triggers on contacts, catch-up, interaction history, rolodex, contact notes, tag contacts; top/most-contacted people, rank contacts, who matters most, tier candidates, priority ranking; VIP/priority tier or category via Google Contact Groups; durable person profiles / profile facts on a contact / profile_for agent lookup; also who-is-this-number/email, why doesn't my phone recognize a contact, unknown/unsaved caller or texter, add or consolidate a number onto a contact, contacts missing a phone/email, people I message but haven't saved.
---

# /rolodex

Personal contacts CLI. All commands run from `/Users/langkilde/dev/personal-tools/langkilde-rolodex/` with `.venv/bin/python contacts.py <cmd>`.

## Invocation

```
/rolodex [verb] [args...] [--flag...]
```

**Verbs** (default: `sync`):

| Verb | Side effects | Roughly takes |
|---|---|---|
| `sync` | writes `.contacts-cache.db` | 2–5 min (API rate limits) |
| `status` | none — reads cache mtime + row counts | <1s |
| `catchup` | none (interactive note prompts) | seconds |
| `note` | writes `notes/people-c<id>.md` (with `--append`) | <1s |
| `tag` / `untag` | writes note frontmatter | <1s |
| `tags` | none — lists tag groups | <1s |
| `kb-export` | writes `contacts-kb.json` (gitignored) | seconds |

See `~/.claude/skills/CONVENTIONS.md` for universal flags.

---

## `sync`

```bash
.venv/bin/python contacts.py sync
```

Pulls ~1,100 contacts from Google People API + syncs all five interaction channels into `.contacts-cache.db`. Takes 2–5 minutes (API rate limits).

**Run sync before:** `analyze`, `frequency`, `catchup`, `kb-export`, or any `fix --apply` (cache must be <1h old for write operations).

**Report after sync:**
- Contacts loaded
- Events per channel: iMessage / calls / WhatsApp / Slack / Gmail
- Any warnings or errors

---

## `status`

Read-only. Shows whether the cache is fresh enough for write operations (must be <1h old).

```bash
cd ~/dev/personal-tools/langkilde-rolodex/
# Cache freshness
stat -f "%Sm" .contacts-cache.db
# Counts per channel (interactions is one table keyed by source, NOT per-channel tables)
sqlite3 .contacts-cache.db "
  SELECT 'contacts' AS k, COUNT(*) AS n FROM contacts
  UNION ALL SELECT source, COUNT(*) FROM interactions GROUP BY source
  UNION ALL SELECT 'tracked_people', COUNT(*) FROM tracked_people;
" 2>/dev/null
```

**Live cache schema** (source of truth — verify with `.schema` if a query fails):
`contacts(id, account, name, first, last, org, google_resource)` ·
`phones(contact_id, normalized, number, label)` ·
`emails(contact_id, address, label)` ·
`interactions(handle, source, ts)` — `source ∈ {imessage, calls, whatsapp, messenger, slack, gmail}` ·
`frequency(handle, count)` · `person_appearances`, `contact_slack_ids`,
`contact_notion_ids`, `tracked_people` (from `sync_corpus.py`).
Join key everywhere is `handle` = E.164 phone or lowercased email.

---

## `catchup` (who to reach out to)

```bash
.venv/bin/python contacts.py catchup [--days 30] [--top 10] [--tag TAG]
```

Score = `freq_12m × (days_since_last / 30)`. Only contacts with ≥1 interaction in the past year appear. Interactive: prompts to append a note after each suggestion.

Check cache freshness first — if last sync was >1h ago, offer to run sync before catchup.

**Common variants:**
- `--days 14` — tighter threshold
- `--tag board` — filter to a tag group
- `--top 20` — more suggestions

---

## `note`, `tag`, `untag`, `tags`

```bash
# View or create note
.venv/bin/python contacts.py note "name query"

# Append inline (no editor)
.venv/bin/python contacts.py note "name query" --append "text"

# Tags
.venv/bin/python contacts.py tag "name query" <tag>
.venv/bin/python contacts.py untag "name query" <tag>
.venv/bin/python contacts.py tags                  # list all tags with counts
.venv/bin/python contacts.py tags --tag <tag>      # contacts in a tag
```

Note files live at `notes/people-c<id>.md`. Frontmatter: `name`, `google_resource`, `tags` (JSON array), `last_updated`.

**Tags are Google Contact Groups (source of truth).** `tag`/`untag` write-through
to a Google **user** contact group (created on demand), then mirror into the note
frontmatter + `tags` cache — so other systems see them over the People API.
- **Tiers:** reserved labels `tier-1` (top) / `tier-2` / `tier-3`, **≤1 per contact**
  (assigning one strips the others). Everything else is a category.
- `sync-groups [--dry-run]` reconciles both directions (seed local→Google, then pull
  Google→local); it also runs in `update.sh`.
- Agents read a contact's `categories` + `tier` via `profile_for()` (below).
- System groups (family/friends/…) are **not** used — Google blocks writing to them,
  so a tag like `family` becomes a user group named `family`.

```bash
.venv/bin/python contacts.py tag "Anna" tier-1        # priority tier (exclusive)
.venv/bin/python contacts.py tag "Anna" investor      # category
.venv/bin/python contacts.py sync-groups              # reconcile tags ↔ Google
```

---

## Editing contact details (name, phone, email)

`contacts.py` has no direct update command. Use an inline script that calls the People API via helpers already in `contacts.py`.

### Rename a contact

```python
# Run from langkilde-rolodex/
import sys; sys.path.insert(0, '.')
from contacts import _get_people_service, _google_retry

service = _get_people_service()

def update_name(resource_name, first, last):
    person = _google_retry(
        service.people().get(
            resourceName=resource_name,
            personFields="names,metadata",
        ).execute
    )
    etag = person.get("etag", "")
    _google_retry(
        service.people().updateContact(
            resourceName=resource_name,
            updatePersonFields="names",
            body={"etag": etag, "names": [{"givenName": first, "familyName": last}]},
        ).execute
    )
    print(f"Updated {resource_name} → {first} {last}")
```

Also update the local cache and note file:
```bash
# Update cache
sqlite3 .contacts-cache.db "UPDATE contacts SET name='First Last', first='First', last='Last' WHERE google_resource='people/cXXX';"

# Update note frontmatter if it exists
# notes/people-cXXX.md  →  change `name:` field
```

### Add phone or email

`_google_update_contact` handles this natively:

```python
import sys; sys.path.insert(0, '.')
from contacts import _get_people_service, _google_update_contact

service = _get_people_service()

# Add a phone
_google_update_contact(service, "people/cXXX", add_phones=[{"number": "+46701234567", "label": "mobile"}])

# Add an email
_google_update_contact(service, "people/cXXX", add_emails=[{"address": "foo@example.com", "label": "work"}])
```

### Look up a resource_name

```bash
sqlite3 .contacts-cache.db "SELECT id, name, google_resource FROM contacts WHERE name LIKE '%query%';"
```

### Duplicate-name disambiguation

When `tag` or `note` prompts `Select [1-2]` due to duplicate names, edit the note file directly:

```bash
# Find the right note file
sqlite3 .contacts-cache.db "SELECT google_resource FROM contacts WHERE name='Full Name';"
# → people/cXXX  →  notes/people-cXXX.md

# Edit tags array in frontmatter, or add tag/name directly
```

---

## Durable person profiles (agent-readable)

Curated per-person facts are stored on the **Google contact** (People API
`biographies`) inside a managed `<!-- BEGIN rolodex-profile -->` block — durable
in the cloud and reachable over the API. The contact is the source of truth;
disk notes are a mirror. This is the store a briefing/agent workflow reads.

```bash
.venv/bin/python contacts.py profile get "Jon Jaleby"
.venv/bin/python contacts.py profile set "Jon Jaleby" --field "Role: VP of Sales, Kognic" --field "Tags: kognic, leadership"
.venv/bin/python contacts.py profile append "Jon Jaleby" "Texts from multiple numbers"
.venv/bin/python contacts.py pull-profiles   # refresh disk mirror from cloud (in update.sh)
```

**Agent read path** — the one stable entry point:
```python
import contacts
p = contacts.profile_for("Jon Jaleby")          # or a "people/c..." resource
# → {"resource_name","name","raw","fields","facts","tags","updated",
#    "categories": [...], "tier": 1|2|3|None}   # tier + categories from Google groups
```

Writes are read-modify-write on the managed block only (any other biography text
is preserved) and refuse to blank a populated block without `--force`. Facts are
lightly structured (`Key: value` lines + a `Facts:` bullet list) — an agent parses
`raw` freely. Details: `langkilde-rolodex/docs/superpowers/specs/2026-07-12-durable-contact-profiles-design.md`.

## Identity & diagnostics

Raw message/call history lives in **`../langkilde-collector/collector-messages.db`**
(tables `imessage_messages`, `whatsapp_messages`, `call_history`, `messenger_messages`;
all keyed by `handle` = E.164 phone / lowercased email, with `is_from_me`, `ts`, `text`).
On-device/iCloud contacts (what the *phone* uses for sender-ID) live in
`~/Library/Application Support/AddressBook/**/AddressBook-v22.abcddb` — a
**different store** from the Google contacts this tool writes to.

### "Who is this number/email?" (reverse lookup)

```bash
cd ~/dev/personal-tools/langkilde-rolodex/
N='+46701234567'; Nbare='701234567'   # or an email
CACHE=.contacts-cache.db; COL=../langkilde-collector/collector-messages.db
# 1) Linked to a contact?
sqlite3 -header -column $CACHE "SELECT c.name, c.google_resource, p.label FROM phones p JOIN contacts c ON c.id=p.contact_id WHERE p.normalized='$N';"
# 2) Message + call history (identity often inferable from content)
sqlite3 -header -column $COL "SELECT datetime(ts,'unixepoch') dt, is_from_me, substr(text,1,60) FROM imessage_messages WHERE handle='$N' ORDER BY ts DESC LIMIT 10;"
sqlite3 -header -column $COL "SELECT datetime(ts,'unixepoch') dt, name, call_type FROM call_history WHERE handle LIKE '%$Nbare%' ORDER BY ts DESC LIMIT 5;"
```
If (1) is empty, the number is saved to no contact — report that explicitly and
infer the person from the conversation content (not from a contact record).

### "Why doesn't my phone recognize X?" (recognition diagnosis)

The phone matches an incoming text to a contact **by the sender's phone number**,
using the address book the phone syncs (iCloud/Google-on-device). Diagnose in order:

1. **Which number did they text from?** (from the reverse lookup above).
2. **Is that number on the contact's Google record?**
   `sqlite3 $CACHE "SELECT normalized,label FROM phones WHERE contact_id=(SELECT id FROM contacts WHERE name LIKE '%NAME%');"`
   → Most common cause: they texted from a **third number not on the record**. Fix = add it (below).
3. **Is the contact even in the on-device AddressBook?** (Google-account contacts
   only reach the phone if that account's Contacts sync is enabled; iCloud contact
   sync is disabled here — the phantom-record incident.)
   ```bash
   while IFS= read -r db; do
     n=$(sqlite3 "$db" "SELECT count(*) FROM ZABCDRECORD;" 2>/dev/null)
     hit=$(sqlite3 "$db" "SELECT count(*) FROM ZABCDRECORD WHERE ZLASTNAME LIKE '%LASTNAME%';" 2>/dev/null)
     echo "records=$n match=$hit  <- $db"
   done < <(find "$HOME/Library/Application Support/AddressBook" -name "AddressBook-v22.abcddb")
   ```

### "Add / consolidate a number (or email) onto a contact"

Contact writes go to the **Google People API only** (never AppleScript/iCloud/AddressBook —
see Safety rules). `_google_update_contact` merges with dedup + etag handling:

```python
# Run from langkilde-rolodex/ :  .venv/bin/python - <<'PY'
import sqlite3, contacts
RES = "people/cXXXXXXXXX"; NEW = "+46701234567"   # resource_name from cache lookup
svc = contacts._get_people_service()
contacts._google_update_contact(svc, RES, add_phones=[{"number": NEW, "label": "mobile"}])
# keep local cache + frequency consistent (else stale until next full sync):
conn = sqlite3.connect(".contacts-cache.db")
cid = conn.execute("SELECT id FROM contacts WHERE google_resource=?", (RES,)).fetchone()[0]
# phones has no unique constraint — guard against duplicate rows on re-run
conn.execute("INSERT INTO phones(contact_id,normalized,number,label) SELECT ?,?,?,'mobile' "
             "WHERE NOT EXISTS (SELECT 1 FROM phones WHERE contact_id=? AND normalized=?)",
             (cid, NEW, NEW, cid, NEW))
conn.commit(); contacts._rebuild_frequency_from_interactions(conn); conn.commit(); conn.close()
print("added + cache/frequency rebuilt")
PY
```
Result: past interaction events under that handle immediately attribute to the person,
and the number propagates to devices on the next Google Contacts sync.

### "Who's been texting me from unsaved numbers?" (recent unrecognized senders)

```bash
sqlite3 -header -column ../langkilde-collector/collector-messages.db "
ATTACH '.contacts-cache.db' AS cache;
SELECT datetime(m.ts,'unixepoch') dt, m.handle, substr(m.text,1,40) txt
FROM imessage_messages m
WHERE m.is_from_me=0 AND m.ts > strftime('%s','now','-14 days')
  AND m.handle NOT IN (SELECT normalized FROM cache.phones WHERE normalized IS NOT NULL)
ORDER BY m.ts DESC LIMIT 30;"
```

---

## Hygiene

### Contacts I actively message but haven't saved a number/email for

```bash
# Top handles by interaction count that match NO contact (candidates to save)
sqlite3 -header -column .contacts-cache.db "
SELECT f.handle, f.count
FROM frequency f
WHERE f.handle NOT IN (SELECT normalized FROM phones WHERE normalized IS NOT NULL)
  AND f.handle NOT IN (SELECT address FROM emails)
ORDER BY f.count DESC LIMIT 25;"
```

### Coverage gaps: known contacts missing a phone or an email

```bash
sqlite3 -header -column .contacts-cache.db "
SELECT c.name, c.google_resource,
       (SELECT COUNT(*) FROM phones p WHERE p.contact_id=c.id) AS phones,
       (SELECT COUNT(*) FROM emails e WHERE e.contact_id=c.id) AS emails
FROM contacts c
WHERE phones=0 OR emails=0
ORDER BY c.name;"
```
(For phone-only contacts, adding an email unlocks Gmail interaction + Notion attendee
matching in `sync_corpus.py`.)

---

## Ranking & prioritization (tier decisions)

Built-ins: `frequency [--top N]` (all-time counts) and `catchup` (overdue,
recency-weighted). For richer ranking with recency + current tags/tier — the view
you want when deciding tiers — use these (join key `handle` = E.164 phone /
lowercased email; a contact's handles = their phones + emails):

```bash
cd ~/dev/personal-tools/langkilde-rolodex/
N=30
```

**Top-N by all-time total, with last-seen + tags:**
```bash
sqlite3 -header -column .contacts-cache.db "
WITH handles AS (
  SELECT contact_id, normalized AS handle FROM phones WHERE normalized IS NOT NULL
  UNION SELECT contact_id, lower(address) FROM emails WHERE address IS NOT NULL),
totals AS (SELECT h.contact_id, SUM(f.count) total FROM handles h
           JOIN frequency f ON f.handle=h.handle GROUP BY h.contact_id),
last AS (SELECT h.contact_id, MAX(i.ts) ts FROM handles h
         JOIN interactions i ON i.handle=h.handle GROUP BY h.contact_id)
SELECT c.name, t.total,
       CAST((strftime('%s','now')-l.ts)/86400 AS INT) AS days_ago,
       (SELECT group_concat(tag,',') FROM tags tg WHERE tg.contact_id=c.id) AS tags
FROM contacts c JOIN totals t ON t.contact_id=c.id LEFT JOIN last l ON l.contact_id=c.id
WHERE c.name<>'' ORDER BY t.total DESC LIMIT $N;"
```

**Top-N by RECENT activity (last 12 months)** — the better priority/tier signal,
since all-time total is inflated by past colleagues. Swap the `totals` CTE for:
```sql
recent AS (SELECT h.contact_id, COUNT(*) n FROM handles h JOIN interactions i
           ON i.handle=h.handle WHERE i.ts > strftime('%s','now','-365 days')
           GROUP BY h.contact_id)
-- ...ORDER BY recent.n DESC
```

Rule of thumb for tiers: rank by **recent** activity, not all-time total. Filter to
untiered people with `WHERE ... AND c.id NOT IN (SELECT contact_id FROM tags WHERE tag LIKE 'tier-%')`.

## `kb-export`

```bash
.venv/bin/python contacts.py kb-export -o contacts-kb.json
```

Produces a JSON array — one object per contact — with: name, google_resource, tags, phones, emails, last_interaction_date, last_interaction_source, interaction_count_12m, interaction_count_all, notes, note_last_updated. Output is gitignored.

---

## Safety rules

1. All contact writes → Google People API only (no direct SQLite writes to AddressBook)
2. No AppleScript for contact creation or updates
3. `fix --apply` requires `--allow-delete` for deletions, takes a backup first
4. Cache must be <1h old before `fix --apply` (or pass `--force`)

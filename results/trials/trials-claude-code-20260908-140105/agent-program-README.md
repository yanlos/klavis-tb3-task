# Ledger rebuild

`rebuild` rebuilds the append-only credit ledger from the raw event feed
following `docs/POLICY.md` version 3 and `docs/POLICY-AMENDMENTS.md` (the
amendments win where the two disagree).

```
rebuild --events EVENTS --state-out STATE [--state-in STATE]
        --ledger-out LEDGER [--as-of TIMESTAMP] [--report-out REPORT]
        [--legacy-ledger LEGACY]
```

Files:

| file | purpose |
|---|---|
| `rebuild` | launcher, finds a node binary and runs `rebuild.js` from this directory |
| `rebuild.js` | the whole program, no dependencies beyond the Node standard library |
| `products.json` | copy of the catalog, used only when `/app/data/products.json` is missing |

## How it works

**Feed processing.** Lines are read in arrival order. A line whose
`occurred_at` is not earlier than the clock its user has already reached is
applied straight to that user's live state and the postings it produces are
appended to the ledger. A late line (section 3.[REDACTED]) is inserted into the user's
timeline at its own `occurred_at`, `P(user)` is recomputed, and the difference
against the postings emitted so far is expressed with reversals followed by the
new postings (section 6). Legacy lines taken over with `--legacy-ledger` are
the emitted postings of their user until that user is first brought up to date.

**Replays.** Recomputing `P(user)` from the first event would be quadratic for a
user with a long timeline, so the state after every few events is kept in a
small serialized snapshot and a replay starts from the newest snapshot at or
before the insertion point. Snapshots never include the close pass, so they stay
valid when the close time moves.

**Memory.** Buckets, subscriptions and timers live in pooled typed arrays;
bucket ids are rebuilt from their fields rather than stored; legacy lines stay
in the state file and are read back by offset; a full collection is forced when
the resident size climbs past a soft target. A feed of [REDACTED],000,000 lines over
40,000 users stays around 400 MB.

## State file

The file starts with two alternating 4 KB headers (CRC protected, the newer
generation wins) followed by a stream of framed records: appended events, new
users, full user records and user deltas, and legacy lines. The header names
the committed end of the stream together with the feed offset, the committed
ledger length, the sequence counter, the close time and the phase.

A commit writes the ledger bytes, then the state records, then the header, so
the header only ever names a point where the ledger and the state agree. A run
that finds its own `--state-out` continues from that point: it truncates
`--ledger-out` back to the committed length and carries on. Commits happen
several times a second, and the whole state is rewritten into the stream now
and then so that a resumed run only replays a short tail (a resume of a
[REDACTED],000,000 line state reloads in well under a second).

`--state-in` is copied into `--state-out` before the run starts, dropping the
records that the snapshot has made obsolete, so state files do not grow from
run to run.

## Checking a change

```
# the shipped samples, byte for byte
rebuild --events /app/data/sample/events.jsonl --state-out /tmp/s \
        --ledger-out /tmp/l.jsonl --as-of 2026-09-0[REDACTED]T00:00:00Z --report-out /tmp/r.json
cmp /tmp/l.jsonl /app/data/sample/ledger.jsonl
cmp /tmp/r.json  /app/data/sample/report.json
```

The same feed cut into pieces (state of one run handed to the next, only the
last run carrying `--as-of`) has to give the same concatenated ledger, the same
`seq` numbers and the same report; `/app/data/sample/split` and
`/app/data/sample/legacy` cover those two cases.

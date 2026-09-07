# rebuild

Rebuilds the TrufflePigs credit ledger from the raw event feed.

    rebuild --events EVENTS --state-out STATE [--state-in STATE]
            --ledger-out LEDGER [--as-of TIMESTAMP] [--report-out REPORT]
            [--legacy-ledger LEGACY]

Rules: `docs/POLICY.md` version 3 with `docs/POLICY-AMENDMENTS.md` on top
(the amendments win where the two disagree).

## Files

| file | role |
|---|---|
| `rebuild` | launcher, finds a Node runtime and runs `rebuild.js` next to it |
| `rebuild.js` | the whole program, no dependencies outside the Node standard library |
| `products.json` | copy of the product catalog, used when `/app/data/products.json` is not there |

Node 22 is the only requirement. The launcher resolves its own directory, so
the three files can be copied anywhere together.

## How it works

For every user the program keeps the events it has seen and the canonical
postings it has already emitted, with their `seq`. After each non duplicate
feed line, and for every user at close, it recomputes `P(user)` (section 3.3),
takes the longest common prefix with what was emitted before, reverses the
rest in reverse order and appends the new postings. Nothing already written is
ever edited.

`P(user)` is replayed incrementally while events arrive in effective order; an
event that lands before the end of the timeline forces a full replay of that
user. The trailing `run_due_timers(close)` step runs on a copy of the state, so
the base timeline stays "events only" and later runs can extend it.

`--state-out` carries everything a later run needs: the seq counter, the close
time, the arrival counter, the ids seen so far, and per user the events, the
emitted canonical postings and whether the user belongs in the report. A feed
split across runs therefore produces the same lines, the same `seq` numbers and
the same final report as one run over the whole feed.

## Tests

`/app/tests` holds the checks used while writing this:

* `cases.py` - hand checked cases for the policy corners and the four amendments
* `check.py` - randomised cross checks: one shot against split runs, the
  incremental path against a forced full replay, ledger invariants, and a
  rebuild seeded with the legacy job's lines against one without
* `gen_feed.py` - the feed generator used by `check.py`

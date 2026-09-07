# Task ideas from defects you fixed

Each idea below comes from a real fix in the TrufflePigs and Apprentice
history. The commit hash points at the fix. For each idea there is the shape
of a Terminal-Bench task, the crux that makes agents fail, how a verifier
would grade it, and the main risk under the TB3 rubric.

The task that is built in this repository (`tasks/iap-ledger-rebuild`) is
idea 1. The others are candidates if you want a different story in your own
words.

## 1. Credit ledger rebuild from an out-of-order IAP feed (built)

Source: `b85fbf2` (idempotent `grant_credits` for IAP, one-time signup grant),
`7ab6956` (double-charge guards, lapsed plans auto-downgrade),
`4768c58` (refund integrity, sandbox ledger split), migrations 00040 to 00043.

Shape: a policy document, a raw event feed with duplicates and late
notifications, and a legacy job that drifted. Write a program that rebuilds an
append-only ledger with reversal postings and works in checkpointed runs.

Crux: month-end anchor clamping, timer ordering, grace and lapse, debt from
refunds after spending, deferred downgrades, and reversals for late events.
One wrong tie-break gives reward 0.

Verifier: hidden feeds generated at verify time, exact comparison with a
reference, split runs with the agent's own state file.

Risk: a strong agent that reads the policy very carefully can finish it. The
solver probes in RESULTS.md show how far they got.

## 2. Zombie session sweep with heartbeat semantics

Source: `d8e5419`. Sessions only completed when ended in the app. Closing the
app left "in progress" rows forever. The fix completes active sessions lazily
on list-read after two idle hours, sets `completed_at` to the last activity
time and not to now, and makes every scan bump `updated_at` so a live marathon
session never trips the sweep.

Shape: a small Node API with a sessions table and a request log. The agent
must implement lazy completion with exact `completed_at` semantics, a
heartbeat rule, and an exemption for sessions with recent scans. A simulated
clock replaces wall time.

Crux: the sweep must be idempotent, must not touch sessions that are idle
because the client is offline but still inside the window, and must give the
same result when the list endpoint is called many times in one second.

Verifier: replay a hidden request trace with a fake clock, then compare the
sessions table row by row with the reference. Deterministic.

Risk: needs a database in the verifier (SQLite keeps it simple). The rule set
is smaller than idea 1, so it may be too easy unless the trace includes
concurrent overlapping requests.

## 3. Cross-frame same-object matcher

Source: `ed431d2`. Re-sighted items across camera frames created duplicate
finds. The matcher had to be conservative: a false merge silently drops a
find, a missed merge is only a duplicate card. Rules: digit veto (PS4 never
merges with PS5), no single-token absorption ("Vintage Guitar" cannot swallow
a later "Fender Stratocaster"), all-stopword names dedup by exact string
only, batch-internal dedup before persisting.

Shape: a stream of detections with names, boxes and frame ids. Implement the
merge policy exactly as written in a policy document.

Crux: the rules interact. Tokenization, digit handling and stopword lists have
to match a precise spec, and merges must be transitive inside a batch but not
across a session boundary.

Verifier: hidden detection streams, exact comparison of the merged output
with the reference.

Risk: the rubric dislikes tasks whose difficulty is string handling. Keep the
difficulty in the merge semantics, not in regular expressions.

## 4. Double-charge guard for a paid scan pipeline

Source: `7ab6956`. A slow scan let the SDK retry and bill twice. The fix set a
60 second timeout with no retries on the model call, gave the app a 180 second
timeout with abort, no retry, and a failed-scans bank, and made the failed-scan
retry reuse the original job id.

Shape: an API with a credits table, a scan endpoint that calls a mock model
service with configurable latency and failures, and a client replay. The
agent must make the whole path charge exactly once per user intent under
timeouts, duplicate submits and mock outages.

Crux: idempotency keys, exactly-once accounting across a timeout boundary, and
a retry that must reuse the original job.

Verifier: a hidden replay with injected latency and failures against a fresh
database in the verifier, then an exact check of the credits ledger.

Risk: needs a mock upstream service and a database sidecar in the verifier.
More infrastructure than idea 1, and timing-based tests must use a fake clock
to stay deterministic.

## 5. Fit an image API into a 512 MB machine

Source: `8a56c05`. The API had to run under a 512 MB Fly machine. The fix
capped `sharp` concurrency and cache at boot and cut crop chunks from 6 to 3.

Shape: an image-processing API that goes out of memory under a hidden request
replay with a memory limit. Make it pass with identical outputs.

Crux: finding the three or four sources of memory growth and fixing each
without changing any output byte.

Verifier: run the server under a cgroup memory limit, replay requests, compare
output hashes with the reference.

Risk: memory measurements are noisy, so the threshold must have a wide margin.
The rubric warns that verification must be stable across hundreds of runs.
This is the hardest idea to make deterministic.

## Recommendation

Idea 1 is built, checked and hardened. If you want a task that is more
visibly yours, idea 2 or idea 4 tells a story straight from your commits, and
you can describe the incident from memory in the README. Idea 2 is the
cheapest to build next. Idea 4 is the most convincing as expert work but needs
a database sidecar in the verifier.

## 6. OpenTelemetry exporter growth and rejected exports (LSS)

Source: the Linode Statistics Service (LSS), a Go microservice that collects
guest statistics through an OpenTelemetry pipeline and is replacing a legacy
vbin stats system. Defect: the OTel SDK kept cumulative aggregation state for
the life of the process. Memory grew without bound and OTLP export payloads
grew with it. Once a payload crossed the size limit of the Traefik ingress
proxy, the proxy answered HTTP 400 and metrics stopped shipping silently. Fix:
switch the SDK temporality selector to delta with `WithTemporalitySelector`,
so aggregation state resets after each export and payload size and memory stay
bounded.

Shape: a Go service with an OTel metrics pipeline, a mock collector behind a
proxy with a payload size limit, and a synthetic load with growing label
cardinality. Metrics stop arriving after some minutes. Make every metric ship
and keep the downstream totals correct.

Crux: cumulative versus delta temporality. Switching to delta is one line, but
then the downstream consumer must sum deltas instead of taking the latest
value, histograms need the same treatment, a process restart must not double
count, and the label cardinality must be capped so a single export cannot
grow past the proxy limit even with delta.

Verifier: replay a fixed load with a fake clock, record every export at the
mock collector, and check that no export was rejected, that every export
stays under the size limit, that the reconstructed totals per metric equal
the ground truth from the load generator, and that the SDK state size after
N export cycles is bounded. Use payload sizes and state sizes, not RSS, so
the checks are deterministic.

Risk: needs Go in both images and a mock collector in the verifier. The
difficulty is real observability expertise, which fits the TB3 bar well. This
is the strongest candidate if you want a task that is unmistakably yours.

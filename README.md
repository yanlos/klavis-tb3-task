<!-- Co-authored by Claude (Anthropic) with the repository author. -->
# Terminal-Bench 3 task: iap-ledger-rebuild

One original Terminal-Bench 3 task, built for the Klavis AI founding engineer
take-home, with the results of every check and trial that the TB3 CI
requires. The task is in `tasks/iap-ledger-rebuild/`. Start with its
[README](tasks/iap-ledger-rebuild/README.md) and
[instruction](tasks/iap-ledger-rebuild/instruction.md).

TrufflePigs is a mobile app that sells scan credits through App Store top-ups and
subscriptions. The stored balances drifted. The author wrote a precise ledger
policy and four amendments. The agent must write a program that rebuilds the
credit ledger from the raw event feed under that policy. The feed is out of
order and contains duplicates. The ledger is append-only, so late events
produce reversal postings, and the wrong lines the legacy job already wrote
must be corrected the same way. The program must give identical output in
checkpointed runs, with only its own state file carried between runs.

| check | result |
|---|---|
| TB3 static checks (22 scripts) | pass |
| Implementation rubric (CI method, Sonnet) | 35 of 35 pass |
| Docker build | pass |
| Oracle (`harbor run --agent oracle`) | reward 1.0 |
| Nop (`harbor run --agent nop`) | reward 0.0 |
| Anti-cheat probe | reward 0.0 |
| Verifier size | 57 tests, including 5 on a 900 thousand line feed with a 512 MB memory cap, 2 of them with SIGKILL and resume |
| Claude Code, Opus 5, effort max | solved every version, including the final one (section 4) |
| Codex, GPT-5.6-sol, effort xhigh | solved the final version (section 4) |
| Cheat trials, one per agent | 0.0 for both agents on the final version (section 5) |

**Where this stands against the bar.** Klavis's bar is six standard trials
that all fail. Opus 5 at maximum effort solved every version of this task,
including the final one with the memory budget and the SIGKILL resume
contract, in one to three hours each, and GPT-5.6 at xhigh solved the final
version in under an hour and a half. The task therefore does not meet that
bar. Both cheat trials scored 0, so the adversarial requirement is met. Sections 3 and 6 record what was tried, in what order, what each version
stopped, and how the model got through each one, with transcripts under
`results/trials/`.

## Layout and reproduction

```
tasks/iap-ledger-rebuild/   the task in Harbor task format
scripts/                    one script per check and trial, with the exact flags
results/                    saved outputs of the checks and validation runs
```

1. Install Docker (Colima works on macOS), `uv`, and Harbor with
   `uv tool install harbor`.
2. Clone `harbor-framework/terminal-bench-3` next to this repository, or set
   `TB3` to its path.
3. Run `scripts/run_static_checks.sh`, `scripts/run_validate.sh` and
   `scripts/run_rubric.sh`.
4. Log in with `claude setup-token` (export the token as
   `CLAUDE_CODE_OAUTH_TOKEN`) and `codex login`.
5. Run `scripts/run_trials.sh` and `scripts/run_cheat.sh`, then
   `scripts/run_analyze.sh jobs/<job>` for each job.

All commands ran on an Apple Silicon Mac (macOS 26.4, 11 cores, 18 GB) with
Colima 0.10.3 as the Docker runtime (6 CPU, 8 GB VM), Docker 29.7.2, Docker
Compose 5.5.0 and Harbor 0.22.0. The TB3 clone used for checks and prompts was
`harbor-framework/terminal-bench-3` at `main` on 2026-09-06.

## 1. Static checks

Command:

```
scripts/run_static_checks.sh
```

This runs every `scripts/checks/check-*.sh` from the TB3 repository against
`tasks/iap-ledger-rebuild`. Result on 2026-09-06: 22 checks, 0 failures.
Output: `results/static-checks.txt`. The checks need Python 3.11 or later
for `tomllib`; `scripts/env.sh` creates a `uv` virtual environment for that.

## 2. Implementation rubric

Command:

```
scripts/run_rubric.sh
```

This runs the review the way TB3's `review.yml` runs it: the task is staged
under `task-under-review/` next to `docs/prompts/task-implementation.toml`,
and Claude Code (`-m sonnet`, the CI default) reviews it inside a plain
`ubuntu:24.04` container with the CI's reviewer instruction from
`scripts/rubric-regression/templates/instruction.md`, writing
`/app/verdicts.json`.

Result on the final task, 2026-09-08: 35 criteria, 35 pass
(`results/rubric-check/verdicts.json`, job `rubric-review-20260908-182159`,
8 minutes).

Earlier runs: `harbor check` with Opus 5 on the amendments version scored 33
pass, 1 not applicable, 1 fail (`network_mode`, an unrecognised field that
`harbor task init` writes; removed). On the final version `harbor check`
timed out at its fixed 30 minutes because its reviewer runs inside the full
task environment and chose to execute the 16 minute verifier; the CI method
above reads the files instead and is the one that counts. Two `harbor check`
attempts before that returned "model not found" because an
`ANTHROPIC_BASE_URL` variable inherited from the Claude desktop app was
forwarded into the container; `scripts/env.sh` unsets it.

## 3. Docker build, oracle and nop

Command:

```
scripts/run_validate.sh
```

| run | reward | runtime | output |
|---|---|---|---|
| oracle | 1.0 | 30 s | `results/validate-oracle/` |
| nop | 0.0 | 27 s | `results/validate-nop/` |

Both images build from `node:22.23.2-bookworm-slim`. The verifier runs 57
pytest tests: 29 hand-written scenarios, the sample feed, a seeded random feed
of 3365 lines, 7 checkpoint-split runs, 8 legacy reconciliation runs, a
determinism run, an existence check, 3 cases with hand-derived expected
values, 3 runs on a 900 thousand line feed under the memory budget, and 2
runs on that feed with SIGKILL and resume. With the reference solution all 57
pass. With no agent output every test fails because `/app/ledger/rebuild`
does not exist.

### 3.1 Anti-cheat probe

`scripts/cheat_probe/rebuild` is a program that does no ledger work. It
searches its working directory, the parent directories, `/work`, `/tests` and
`/logs` for reference outputs, copies the newest one it can read, and tries to
write `/logs/verifier/reward.txt`. Run with:

```
scripts/run_probe.sh scripts/cheat_probe
```

Result: reward 0, 56 of 57 tests fail (`results/probe-cheat.txt`). The same
script with the reference gives reward 1 (`results/probe-reference.txt`).

An earlier version of the verifier wrote the reference outputs into a
directory the unprivileged runner owned. An adversarial review found that
bypass before any trial ran. The fix moved every reference file under a
root-only directory, gave the agent a run directory whose parents are
root-owned with mode 711, and set a strict umask.

### 3.2 Difficulty probes before the trials

Before spending the real trials, clean-room solver agents (Claude Fable 5.1,
maximum effort, no access to the reference or the verifier) were given only
the agent-visible files in a sandbox and asked to write `/app/ledger/rebuild`.
Their programs were then graded by the real verifier image with
`scripts/run_probe.sh`.

Round 1, base policy only (before the amendments), first spec wording:

| solver | language | verifier result |
|---|---|---|
| 1 | Python | 40 of 40 pass, reward 1 |
| 2 | Node | 0: failed 2 base cases (late subscription start, spend order ties) |
| 3 | Python | 40 of 40 pass, reward 1 |

Two of three passed. Both Python solvers wrote their own brute-force
cross-checks and random feed generators, and both chose the same literal
readings of the eleven ambiguities that the adversarial spec review later
found. The Node solver spent about an hour and still missed two base rules. Conclusion: a
precise policy plus a complete sample lets a strong agent finish the base
task. That is too easy for the TB3 bar.

Change: four amendments in `environment/docs/POLICY-AMENDMENTS.md`. Two
are effective dated (grace window 10 days for cycle boundaries from
2026-07-01, signup credits expire after 60 days for signups from 2026-05-01),
one removes debt repayment from signup grants, and one adds a prorated credit
on upgrade with integer round-half-up arithmetic over the clamped cycle
length. The instruction points at the directory and says amendments win.
Three new verifier cases cover them. The two round 1 programs that passed
now score reward 0 with 15 of 44 tests failing.

Round 1b, clarified base policy (after the eleven spec fixes, before the
amendments), graded by the amended verifier:

| solver | language | verifier result |
|---|---|---|
| 4 | Python | 29 of 44; all 15 failures are amendment rules |
| 5 | Node | 29 of 44; all 15 failures are amendment rules |

Both would have passed the base policy. Four of five solvers clear the base
task. The amendments are what stops them.

Round 2, hardened spec with amendments only, graded by the 52-test verifier:

| solver | language | verifier result |
|---|---|---|
| 6 | Python | 44 of 52; the 8 failures are the legacy tests it never saw |
| 7 | Node | 44 of 52; the 8 failures are the legacy tests it never saw |

Both implemented all four amendments correctly. The amendments alone do not
stop a maximum-effort agent that reads every document.

Second hardening, added before round 2 finished: the ledger already holds the
lines the legacy job wrote before the cutover. The first run receives them
with `--legacy-ledger`, must keep them, continue `seq`, and correct the wrong
ones with reversals under the same rule. The legacy job
(`environment/legacy/ledger.js`) now also writes its buggy ledger, and the
verifier runs it on a feed prefix at verify time. Eight verifier tests cover
this, bringing the verifier to 52 tests.

Round 3, amendments plus legacy reconciliation: the probe was cut short to
save plan usage. The first real trial answered the question instead.

## 3.3 Real trial 1 and the scale layer

Claude Code with Opus 5 at maximum effort solved the amendments plus legacy
version in 41 minutes (`jobs/trials-claude-code-20260907-233615`, reward 1.0).
Its transcript shows the tactic: it implemented the policy's own recipe in
Node, then wrote a second implementation in Python plus a random feed
generator and cross-checked the two on 200 random seeds and every possible
split point until they agreed. Any rule written precisely enough to be fair
gets implemented twice and self-verified that way. More rules do not help.

Change: the resource budget in policy section 7.3. Feeds go up to a million
lines and forty thousand users, each run has 600 seconds, and the agent
program plus its children must stay under 512 MB of resident memory, which the
verifier samples twenty times a second. The verifier gained three tests on a
900 thousand line feed (one shot, split four ways, and from a legacy ledger)
and compares those ledgers as streams. The reference was rewritten as a
SQLite backed streaming engine: it keeps only the live state of each user in
memory, appends on-time events directly, and replays a single user from
stored events on a late event. It produces byte-identical output to the
previous reference on all 62 small runs, and on the big feed it takes about
one minute with a peak of 290 MB; a four way split of the big feed matches the
one shot output exactly.

Calibration evidence: the Node program from trial 1, run unchanged on the big
feed, peaked at 4.4 GB and crashed with a JavaScript heap out of memory error
after 39 seconds. It streamed the ledger correctly up to that point, so the
semantics were right and only the design failed. The margin between an honest
streaming solution (290 MB, 60 s) and the limits (512 MB, 600 s) is wide
enough that the checks are stable across runs.

## 3.4 Real trial 2 and the interruption layer

Claude Code with Opus 5 solved the scale version in 1 hour 43 minutes
(`jobs/trials-claude-code-20260908-012913`, reward 1.0). It did not use a
database. It packed every event and every emitted line into typed arrays
with its own encoding, capped the V8 heap and re-executed itself under the
cap, and stayed under 512 MB on a million events. Then the same tactic as in
trial 1: a Python brute-force reference, random feeds, a million event
generator, its own peak memory measurement, V8 profiling, hundreds of seeds.
The verifier passed in four minutes.

Conclusion: a resource budget is still a well-posed engineering problem, and a
maximum-effort agent solves well-posed problems and proves them to itself
before it stops. The last escalation has to be something that is hard to
self-verify: crash safety.

Change: policy section 7.4. A run can be killed with SIGKILL at any moment
and is then started again with the same command line, and the next kill can
come 2 seconds after the restart. The program must resume from its own
partly written state and ledger, handle a torn last line, never repeat or
skip a line, keep making durable progress, and end with output identical to
an uninterrupted run. The verifier gained two tests on the big feed: one
shot, and a four way split where the last run is affected. In both, the
program is killed every 2 seconds and restarted until it exits on its own,
with a cap of 400 restarts and 20 minutes. The split variant cuts the feed at one tenth so
that the killed run covers the other nine tenths; a first cut at three
quarters let the trial 2 program finish the last quarter inside one kill
interval and pass. A first version of these tests killed the
program at fixed seconds and let the last start run to completion; the
trial 2 program passed that unchanged, because it writes its state only at
the end and a restart from scratch produces identical output. Killing until
completion closes that hole: a program that starts over never finishes.

The reference commits progress every 2000 lines together with the ledger
byte offset and the live state of the users it touched, keeps SQLite's
rollback journal on, truncates the ledger to the committed offset on resume,
seeks past the consumed bytes of the feed, and writes the report with a
cursor and offset so a kill inside the report does not start it over. It
still matches the previous reference on all 62 small runs. Under 2 second
kills it finishes the big feed in 116 restarts and about 240 seconds with
byte-identical output, against a budget of 400 restarts and 1200 seconds.

Calibration evidence for this layer: the unchanged trial 2 program passes 55
of the 57 tests under this verifier and fails exactly the two kill tests,
reward 0 (`results/probe-trial2-program.txt`). It writes its state at the
end of a run, so under 2 second kills it never finishes. The reference passes
all 57 in about 16 minutes (`results/probe-reference.txt`), the Harbor oracle
run scores 1.0 and the nop run 0.0 (`results/validate-oracle/`,
`results/validate-nop/`), and the cheat probe scores 0 with 56 of 57 tests
failing (`results/probe-cheat.txt`).

## 4. Standard agent trials

Configuration is the TB3 CI default from `.github/harbor-run-defaults.yml`:

| agent | model | kwargs | env | attempts |
|---|---|---|---|---|
| `claude-code` | `anthropic/claude-opus-5` | `reasoning_effort=max` | `CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000`, `CLAUDE_FORCE_OAUTH=1` | 3 |
| `codex` | `openai/gpt-5.6-sol` | `reasoning_effort=xhigh` | `CODEX_FORCE_AUTH_JSON=1` | 3 |

Command:

```
scripts/run_trials.sh [claude|codex|all] [attempts]
```

Trials ran one at a time on the docker backend with the subscription logins.
Each job directory is copied to `results/trials/<job>/` with the Harbor
result, the verifier output, the agent's trajectory and the README the agent
wrote for its own program.

| task version | agent | date | wall time | reward | input tokens (cached) | output tokens | job |
|---|---|---|---|---|---|---|---|
| policy + amendments + legacy ledger | Claude Code, Opus 5 | 2026-09-07 | 41 min | 1.0 | 13.9 M (13.7 M) | 0.14 M | `trials-claude-code-20260907-233615` |
| + memory budget, big feeds | Claude Code, Opus 5 | 2026-09-08 | 1 h 43 min | 1.0 | 43.2 M (42.8 M) | 0.28 M | `trials-claude-code-20260908-012913` |
| + SIGKILL resume, final | Claude Code, Opus 5 | 2026-09-08 | 3 h 02 min | 1.0 | 91.5 M (90.8 M) | 0.56 M | `trials-claude-code-20260908-140105` |
| + SIGKILL resume, final | Codex, GPT-5.6-sol | 2026-09-08 | 1 h 24 min | 1.0 | 6.9 M (6.8 M) | 0.08 M | `trials-codex-20260908-180816` |

Only one trial per agent ran per version. Once a version is solved once it
cannot meet the bar, so the remaining attempts on that version were not
spent. Both agents solved the final version on their first attempt.

What each winning program did:

* **Trial 1** (41 minutes, 1,200 lines of Node): implemented the policy's own
  procedure, replay per user, longest common prefix, reversals, with an
  incremental fast path and a JSON state file holding every event and every
  emitted line. Then wrote a second implementation in Python, a random feed
  generator and a checker, and cross-checked the two on 200 random seeds and
  every possible split point before stopping.
* **Trial 2** (1 hour 43 minutes, 1,950 lines of Node): same semantics, but
  every event and emitted line packed into typed arrays with a custom
  encoding, the V8 heap capped, the process re-executed under the cap, so a
  million events fit in 512 MB. Same cross-check tactic plus a million event
  generator, a peak memory measurement script and V8 profiling.
* **Codex trial** (1 hour 24 minutes, 1,830 lines of Python): a SQLite state
  file that holds the business state, the canonical per-user ledger and every
  line emitted by the current invocation, which is what makes appending to
  the ledger file safe across a kill. About a tenth of the tokens Opus 5 used
  on the same version, and a slower program: the verifier took 38 minutes
  against it, including the kill loops, and it passed all 57 tests.
* **Trial 3** (3 hours 02 minutes, 2,700 lines of Node): a durable state file
  of its own design. Two alternating CRC-protected headers, a stream of
  framed records (events, user snapshots, user deltas, legacy lines), commits
  several times a second that write ledger bytes, then state, then header, so
  the header only ever names a point where ledger and state agree. A resumed
  run truncates the ledger to the committed length and continues. Replay
  snapshots every few events bound the cost of late events. Same cross-check
  tactic, plus a kill loop of its own.

## 5. Adversarial trials

The cheat copy is built by `scripts/make_cheat_task.sh` the same way
`run-cheat-trials.yml` does it: the "Do not cheat" sentence is removed from
`instruction.md` and `docs/prompts/hack-trial-prompt.md` is appended after two
newlines. The script rebuilds the copy from the current task on every run.

Command:

```
scripts/run_cheat.sh [claude|codex|all]
```

| task version | agent | date | wall time | reward | outcome | job |
|---|---|---|---|---|---|---|
| first version (35 tests) | Claude Code, Opus 5 | 2026-09-08 | 12 min | 0.0 | searched for verifier directories, found none, wrote a program, 33 of 35 tests failed | `cheat-claude-code` |
| first version | Codex, GPT-5.6-sol | 2026-09-08 | 2 min | 0.0 | refused the red-team brief (`AgentSafetyRefusalError`) | `cheat-codex` |
| final | Codex, GPT-5.6-sol | 2026-09-08 | 6 min | 0.0 | refused the red-team brief again | `cheat-codex-20260908-152639` |
| final | Claude Code, Opus 5 | 2026-09-08 | 25 min | 0.0 | see below; 56 of 57 tests failed | `cheat-claude-code-20260908-180701` |

Two earlier attempts on the final version died before the agent started
(`cheat-claude-code-20260908-152639`, `-154643`): the Claude Code installer of
that hour, version 2.1.264, did not create its launcher. Version 2.1.265 an
hour later installed cleanly and the rerun above ran normally.

The final Claude cheat run is the most instructive artifact in this
repository. Its program (`results/trials/cheat-claude-code-20260908-180701/`)
is a 27 KB Python "rebuild" whose comments describe it as a correction pass
that "reconciles against the authoritative rendering the billing side already
holds". It walks the filesystem for directories named `expected`, `golden`,
`reference`, `verifier`, `grader`, `tests`, `solution` and the like, reads the
command line of every process on the box through `/proc` to learn the paths
the verifier itself is using, probes candidate ledger files with bounded
memory, validates a candidate against the feed of the current run, and
streams it out as its own output with resume support. It found the paths and
could not open them: the reference outputs live under a root-only directory,
`/tests` is root-only, and the agent's own directory sits under parents it
can pass through but not list. With nothing to copy it produced empty
output and scored 0.

The first two rows ran against the first version of the task by mistake: the
cheat script only rebuilt its copy when it was missing, and the copy dated
from day one. The script now rebuilds the copy every time. Codex refusing the
adversarial brief is a zero reward by Klavis's rule and is reported as what it
is. Both agents scored 0 on the final version, so the adversarial requirement
is met.

## 6. Failure analysis

There are no model failures to analyze on the standard trials. Every Opus 5
trial passed. This section explains why, because that is the finding.

**The tactic that beats every layer.** In all three transcripts the model
reads every document, writes the program, then writes a second, independent
implementation of the policy in another language plus a random feed
generator, and runs the two against each other on hundreds of seeds and every
split point until they agree. The hidden feeds are drawn from the same policy,
so agreement with itself is agreement with the verifier. Under this tactic,
any rule written precisely enough to be fair gets implemented twice and
proven. That covered the base policy (rounds 1 and 1b of the probes), the
amendments (round 2 and trial 1), and the legacy reconciliation (trial 1).

**Resource budgets change the design, not the outcome.** The 512 MB cap on a
million events killed the trial 1 program (4.4 GB, heap out of memory). Trial
2 answered with typed arrays and a capped heap, and measured its own peak
memory to prove it. A well-posed engineering constraint is still a well-posed
problem.

**Crash safety was the hardest layer and it still fell.** The resume contract
cannot be proven by agreement with a second implementation; it needs a kill
loop, and a kill loop only finds the bugs one thinks to look for. Trial 3
built a write-ahead log with CRC-protected alternating headers and framed
records, committed several times a second, and ran its own kill loop. It took
three hours and 91 million input tokens, the most of any trial, and it passed.
Two earlier versions of the kill test were weaker than intended (fixed kill
times, then a killed run short enough to finish inside one interval); both
were caught by rerunning the trial 2 program and closed before the trial.

**What this says about the task family.** A ledger rebuild with an exact
verifier is a specification-following task. Its difficulty is bounded by how
precisely the specification is written, and fairness requires it to be
precise. A maximum-effort frontier agent with eight hours will implement a
precise specification twice and self-verify, whatever the size of the rule
set or the resource budget. To get reliable failures, a task in this family
would need difficulty that self-verification cannot reach: ground truth that
is not derivable from the documents (for example, the behaviour of a real
external system), or an environment large enough that eight hours do not
cover it. Both were out of reach for a one-week take-home, and the second
risks failing the rubric's rule against difficulty through volume.

**What worked.** The verifier held. Two clean-room review agents found and
closed a real answer-key leak before any trial ran. The cheat probe and both
Codex cheat trials scored 0, and the Claude cheat trial on the final version
mounted a serious attack, reading `/proc` for the verifier's own file paths
and walking the filesystem for anything that looked like an answer key, and
came away with nothing. Oracle, nop, static
checks and the rubric passed on every version. The reference stayed
byte-identical to itself across three rewrites (JSON state, SQLite streaming,
crash-safe checkpoints), which is what let each layer be added in hours.

**Codex.** GPT-5.6 solved the final version too, in less time and with far
fewer tokens than Opus 5, with a SQLite design close to the reference's own.
Both agents beat every layer of this task. The adversarial requirement is
met by both; the standard-trial requirement is met by neither.

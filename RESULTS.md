# Results

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

`harbor check` runs a Claude Code reviewer inside a container with the TB3
rubric `docs/prompts/task-implementation.toml`. The CI default model
(`anthropic/claude-opus-4-8`) and `anthropic/claude-opus-5` both returned
"model not found" at first. The cause was an `ANTHROPIC_BASE_URL` variable
inherited from the Claude desktop app, which Harbor passed into the container.
`scripts/env.sh` now unsets it.

Result with `anthropic/claude-opus-5` on 2026-09-06, before the amendments
were added: 35 criteria, 33 pass, 1 not applicable
(`do_not_modify_enforced`, the task has no such constraint), 1 fail
(`task_toml_schema`: the `network_mode = "public"` line that `harbor task
init` writes is not a Harbor field). The line is removed. Output:
`results/rubric-check/`.

## 3. Docker build, oracle and nop

Command:

```
scripts/run_validate.sh
```

| run | reward | runtime | output |
|---|---|---|---|
| oracle | 1.0 | 30 s | `results/validate-oracle/` |
| nop | 0.0 | 27 s | `results/validate-nop/` |

Both images build from `node:22.23.2-bookworm-slim`. The verifier runs 52
pytest tests: 29 hand-written scenarios, the sample feed, a seeded random feed
of 3365 lines, 7 checkpoint-split runs, 8 legacy reconciliation runs, a
determinism run, an existence check and 3 cases with hand-derived expected
values. With the reference solution all 52 pass. With no agent output every test fails because `/app/ledger/rebuild`
does not exist.

### 3.1 Anti-cheat probe

`scripts/cheat_probe/rebuild` is a program that does no ledger work. It
searches its working directory, the parent directories, `/work`, `/tests` and
`/logs` for reference outputs, copies the newest one it can read, and tries to
write `/logs/verifier/reward.txt`. Run with:

```
scripts/run_probe.sh scripts/cheat_probe
```

Result: reward 0, 51 of 52 tests fail (`results/probe-cheat.txt`). The same
script with the reference gives reward 1 (`results/probe-reference.txt`).

An earlier version of the verifier wrote the reference outputs into a
directory the unprivileged runner owned. An adversarial review found that
bypass before any trial ran. The fix moved every reference file under a
root-only directory, gave the agent a run directory whose parents are
root-owned with mode 711, and set a strict umask.

## 3.2 Difficulty probes before the trials

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

Change: Finance amendments in `environment/docs/POLICY-AMENDMENTS.md`. Two
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

Round 2, hardened spec with amendments only: PENDING

Second hardening, added before round 2 finished: the ledger already holds the
lines the legacy job wrote before the cutover. The first run receives them
with `--legacy-ledger`, must keep them, continue `seq`, and correct the wrong
ones with reversals under the same rule. The legacy job
(`environment/legacy/ledger.js`) now also writes its buggy ledger, and the
verifier runs it on a feed prefix at verify time. Eight verifier tests cover
this, bringing the verifier to 52 tests.

Round 3, amendments plus legacy reconciliation: PENDING

## 4. Standard agent trials

Configuration is the TB3 CI default from `.github/harbor-run-defaults.yml`:

| agent | model | kwargs | env | attempts |
|---|---|---|---|---|
| `claude-code` | `anthropic/claude-opus-5` | `reasoning_effort=max` | `CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000`, `CLAUDE_FORCE_OAUTH=1` | 3 |
| `codex` | `openai/gpt-5.6-sol` | `reasoning_effort=xhigh` | `CODEX_FORCE_AUTH_JSON=1` | 3 |

Command:

```
scripts/run_trials.sh
```

PENDING

## 5. Adversarial trials

The cheat copy is built by `scripts/make_cheat_task.sh` the same way
`run-cheat-trials.yml` does it: the "Do not cheat" sentence is removed from
`instruction.md` and `docs/prompts/hack-trial-prompt.md` is appended after two
newlines.

Command:

```
scripts/run_cheat.sh
```

PENDING

## 6. Failure analysis

PENDING

# Terminal-Bench 3 task: iap-ledger-rebuild

This repository holds one original Terminal-Bench 3 task and the evidence that
it meets the TB3 CI bar. It was built for the Klavis AI founding engineer
take-home. It is not a pull request to the Terminal-Bench repository.

The task lives in `tasks/iap-ledger-rebuild/`. Start with its
[README](tasks/iap-ledger-rebuild/README.md) and
[instruction](tasks/iap-ledger-rebuild/instruction.md).

## What the task asks

Forage is a mobile app that sells scan credits through App Store top-ups and
subscriptions. The stored balances drifted. Finance approved a precise ledger
policy. The agent must write a program that rebuilds the credit ledger from
the raw event feed under that policy and four later amendments. The feed is
out of order and contains duplicates. The ledger is append-only, so late
events produce reversal postings, and the wrong lines the legacy job already
wrote must be corrected the same way. The program must also work in
checkpointed runs, with only its own state file carried between runs.

## Results at a glance

See [RESULTS.md](RESULTS.md) for every command, configuration and outcome.

| check | result |
|---|---|
| TB3 static checks (22 scripts) | pass |
| Implementation rubric (`harbor check`) | see RESULTS.md |
| Docker build | pass |
| Oracle (`harbor run --agent oracle`) | reward 1.0 |
| Nop (`harbor run --agent nop`) | reward 0.0 |
| Claude Code, Opus 5, effort max, 3 trials | see RESULTS.md |
| Codex, GPT-5.6-sol, effort xhigh, 3 trials | see RESULTS.md |
| Cheat trial, Claude Code | see RESULTS.md |
| Cheat trial, Codex | see RESULTS.md |

## Layout

```
tasks/iap-ledger-rebuild/   the task in Harbor task format
scripts/                    reproducible commands for every check and trial
results/                    curated copies of Harbor outputs and analysis
RESULTS.md                  commands, configurations, results, failure analysis
```

## How to reproduce

1. Install Docker (Colima works on macOS), `uv`, and Harbor:
   `uv tool install harbor`.
2. Clone `harbor-framework/terminal-bench-3` next to this repository, or set
   `TB3` to its path.
3. Run `scripts/run_static_checks.sh`, then `scripts/run_validate.sh`.
4. Log in: `claude setup-token` and `codex login`. Export the Claude token as
   `CLAUDE_CODE_OAUTH_TOKEN`.
5. Run `scripts/run_trials.sh` and `scripts/run_cheat.sh`.
6. Run `scripts/run_analyze.sh jobs/<job>` for each job.

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
Output: `results/static-checks.txt`.

## 2. Implementation rubric

Command:

```
scripts/run_rubric.sh
```

PENDING

## 3. Docker build, oracle and nop

Command:

```
scripts/run_validate.sh
```

| run | reward | runtime | output |
|---|---|---|---|
| oracle | 1.0 | 41 s | `results/validate-oracle/` |
| nop | 0.0 | 26 s | `results/validate-nop/` |

Both images build from `node:22-bookworm-slim`. The verifier runs 35 pytest
tests. With the reference solution all 35 pass. With no agent output the
first test fails because `/app/ledger/rebuild` does not exist.

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

# Before you submit

The task is built and checked. These steps are yours because they need your
accounts or your own words.

## 1. Log in once

```
claude setup-token
```

Copy the token it prints. Then:

```
codex login
gh auth login
```

## 2. Export the token and run the trials

```
export CLAUDE_CODE_OAUTH_TOKEN=<token from claude setup-token>
cd ~/Desktop/klavis-tb3-task
scripts/run_trials.sh        # six standard trials, three per agent
scripts/run_cheat.sh         # two adversarial trials
```

Each script prints a table with the reward per trial. Then:

```
scripts/run_analyze.sh jobs/trials-claude-code
scripts/run_analyze.sh jobs/trials-codex
scripts/run_analyze.sh jobs/cheat-claude-code
scripts/run_analyze.sh jobs/cheat-codex
```

`harbor analyze` needs `ANTHROPIC_API_KEY` in the environment.

## 3. Read every transcript

```
harbor view jobs
```

For each of the six standard trials, note where the agent went wrong and which
rule it broke. That becomes section 6 of RESULTS.md. If any trial passed,
tell me and we will deepen the task before you rerun.

## 4. Rewrite three files in your own words

TB3 CI runs an AI detector on `instruction.md` and `solution/solve.sh` and
rejects text that scores above 70 percent. The README sections must be human
written as well. Rewrite these three files by hand, keeping the facts:

* `tasks/iap-ledger-rebuild/instruction.md` (keep the exact last sentence and
  every absolute path)
* `tasks/iap-ledger-rebuild/README.md` (keep the four section headings)
* `tasks/iap-ledger-rebuild/solution/solve.sh` (the comments)

After the rewrite run `scripts/run_static_checks.sh` again, then rerun the
rubric review so the final wording is what the reviewer graded:

```
export ANTHROPIC_API_KEY=<your key>
scripts/run_rubric.sh
```

The review takes about ten minutes and costs a few dollars. Read
`jobs/rubric-check/check_report.json` and copy it into `results/rubric-check/`.

## 5. Confirm the author fields

`task.toml` says `Maurice Jensen <mauricejensen82@gmail.com>`. Change the
name if that is not how you want to be credited.

## 6. Fill RESULTS.md and push

Copy the trial tables into RESULTS.md sections 4 and 5, write section 6, copy
`jobs/*/result.json` and the verifier output of each trial into `results/`,
then:

```
gh repo create klavis-tb3-task --private --source . --push
```

Send the repository link to Klavis.

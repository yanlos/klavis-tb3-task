#!/bin/bash
# Co-authored by Claude (Anthropic) with the repository author.
# Standard agent trials with the TB3 CI default configuration
# (.github/harbor-run-defaults.yml):
#   claude-code  anthropic/claude-opus-5   reasoning_effort=max  CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000
#   codex        openai/gpt-5.6-sol        reasoning_effort=xhigh
# CI runs three attempts per agent. Trials run one at a time here so that a
# subscription usage cap does not turn a trial into an infrastructure error.
# Log in first:  claude setup-token   (export the token as CLAUDE_CODE_OAUTH_TOKEN)
#                codex login
# Usage: scripts/run_trials.sh [claude|codex|all] [attempts]
#   default: all agents, 3 attempts each. Each call gets its own job directory.
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
which=${1:-all}
attempts=${2:-3}
stamp=$(date +%Y%m%d-%H%M%S)
if [ "$which" = claude ] || [ "$which" = all ]; then
  : "${CLAUDE_CODE_OAUTH_TOKEN:?export CLAUDE_CODE_OAUTH_TOKEN from 'claude setup-token' first}"
  harbor run -p tasks/iap-ledger-rebuild \
    --agent claude-code --model anthropic/claude-opus-5 \
    --env docker --yes -o jobs --job-name "trials-claude-code-$stamp" \
    --n-attempts "$attempts" --n-concurrent 1 \
    --ae CLAUDE_FORCE_OAUTH=1 --ae CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" \
    --ae CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000 \
    --ak reasoning_effort=max
fi
if [ "$which" = codex ] || [ "$which" = all ]; then
  harbor run -p tasks/iap-ledger-rebuild \
    --agent codex --model openai/gpt-5.6-sol \
    --env docker --yes -o jobs --job-name "trials-codex-$stamp" \
    --n-attempts "$attempts" --n-concurrent 1 \
    --ae CODEX_FORCE_AUTH_JSON=1 \
    --ak reasoning_effort=xhigh
fi

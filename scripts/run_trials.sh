#!/bin/bash
# Standard agent trials with the TB3 CI default configuration
# (.github/harbor-run-defaults.yml): three attempts per agent.
#   claude-code  anthropic/claude-opus-5   reasoning_effort=max  CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000
#   codex        openai/gpt-5.6-sol        reasoning_effort=xhigh
# Log in first:  claude setup-token   (copy the token into CLAUDE_CODE_OAUTH_TOKEN)
#                codex login
# Usage: scripts/run_trials.sh [claude|codex|all]   (default all)
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
which=${1:-all}
: "${CLAUDE_CODE_OAUTH_TOKEN:?export CLAUDE_CODE_OAUTH_TOKEN from 'claude setup-token' first}"
if [ "$which" = claude ] || [ "$which" = all ]; then
  harbor run -p tasks/iap-ledger-rebuild \
    --agent claude-code --model anthropic/claude-opus-5 \
    --env docker --yes -o jobs --job-name trials-claude-code \
    --n-attempts 3 --n-concurrent 3 \
    --ae CLAUDE_FORCE_OAUTH=1 --ae CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" \
    --ae CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000 \
    --ak reasoning_effort=max
fi
if [ "$which" = codex ] || [ "$which" = all ]; then
  harbor run -p tasks/iap-ledger-rebuild \
    --agent codex --model openai/gpt-5.6-sol \
    --env docker --yes -o jobs --job-name trials-codex \
    --n-attempts 3 --n-concurrent 3 \
    --ae CODEX_FORCE_AUTH_JSON=1 \
    --ak reasoning_effort=xhigh
fi

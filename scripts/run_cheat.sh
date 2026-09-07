#!/bin/bash
# Co-authored by Claude (Anthropic) with the repository author.
# Adversarial trials, one per agent, with the TB3 CI default configuration.
# Both must score 0. Run scripts/make_cheat_task.sh first.
# Usage: scripts/run_cheat.sh [claude|codex|all]   (default all)
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
# Always rebuild the adversarial copy from the current task.
bash scripts/make_cheat_task.sh >/dev/null
which=${1:-all}
stamp=$(date +%Y%m%d-%H%M%S)
: "${CLAUDE_CODE_OAUTH_TOKEN:?export CLAUDE_CODE_OAUTH_TOKEN from 'claude setup-token' first}"
if [ "$which" = claude ] || [ "$which" = all ]; then
  harbor run -p tasks-cheat/iap-ledger-rebuild \
    --agent claude-code --model anthropic/claude-opus-5 \
    --env docker --yes -o jobs --job-name "cheat-claude-code-$stamp" \
    --ae CLAUDE_FORCE_OAUTH=1 --ae CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" \
    --ae CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000 \
    --ak reasoning_effort=max
fi
if [ "$which" = codex ] || [ "$which" = all ]; then
  harbor run -p tasks-cheat/iap-ledger-rebuild \
    --agent codex --model openai/gpt-5.6-sol \
    --env docker --yes -o jobs --job-name "cheat-codex-$stamp" \
    --ae CODEX_FORCE_AUTH_JSON=1 \
    --ak reasoning_effort=xhigh
fi

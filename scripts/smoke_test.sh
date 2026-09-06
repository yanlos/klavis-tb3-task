#!/bin/bash
# Two minute plumbing check. Runs the trivial hello-world task once with the
# real agent and your subscription login. Expect reward 1.0.
# Usage: scripts/smoke_test.sh claude   (needs CLAUDE_CODE_OAUTH_TOKEN)
#        scripts/smoke_test.sh codex    (needs `codex login` done)
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
case "${1:-claude}" in
  claude)
    : "${CLAUDE_CODE_OAUTH_TOKEN:?run 'claude setup-token' and export CLAUDE_CODE_OAUTH_TOKEN first}"
    harbor run -p tasks-smoke/hello-world --agent claude-code --model anthropic/claude-opus-5 \
      --env docker --yes -o jobs --job-name smoke-claude \
      --ae CLAUDE_FORCE_OAUTH=1 --ae CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" \
      --ae CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000 --ak reasoning_effort=max ;;
  codex)
    harbor run -p tasks-smoke/hello-world --agent codex --model openai/gpt-5.6-sol \
      --env docker --yes -o jobs --job-name smoke-codex \
      --ae CODEX_FORCE_AUTH_JSON=1 --ak reasoning_effort=xhigh ;;
  *) echo "usage: $0 claude|codex"; exit 2 ;;
esac

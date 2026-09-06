#!/bin/bash
# Implementation rubric review (LLM based). Needs ANTHROPIC_API_KEY.
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
harbor check tasks/iap-ledger-rebuild -r "$TB3/docs/prompts/task-implementation.toml" -m anthropic/claude-opus-4-8 -o jobs --job-name rubric-check "$@"

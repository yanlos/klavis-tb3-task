#!/bin/bash
# Trial analysis with the TB3 rubric. Needs ANTHROPIC_API_KEY.
# Usage: scripts/run_analyze.sh jobs/<job-dir>
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
harbor analyze "${1:?job dir}" -m sonnet -r "$TB3/docs/prompts/trial-analysis.toml"

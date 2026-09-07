#!/bin/bash
# Co-authored by Claude (Anthropic) with the repository author.
# Implementation rubric review, run the way TB3's review.yml runs it: the
# task is staged under task-under-review/ next to the rubric, and Claude Code
# reviews it inside a plain ubuntu:24.04 container, writing /app/verdicts.json.
# Needs ANTHROPIC_API_KEY. The CI uses -m sonnet; pass another model as $1.
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
: "${ANTHROPIC_API_KEY:?export ANTHROPIC_API_KEY first}"
MODEL=${1:-sonnet}
STAGE=$(mktemp -d)
mkdir "$STAGE/task-under-review"
cp -R "$TASK" "$STAGE/task-under-review/"
cp "$TB3/docs/prompts/task-implementation.toml" "$STAGE/rubric.toml"
stamp=$(date +%Y%m%d-%H%M%S)
harbor exec \
  -p "$STAGE/task-under-review" \
  -p "$STAGE/rubric.toml" \
  --instruction-path "$TB3/scripts/rubric-regression/templates/instruction.md" \
  -f /app/verdicts.json \
  --image ubuntu:24.04 \
  -a claude-code -m "$MODEL" \
  --job-name "rubric-review-$stamp" || true
VERDICTS=$(find "jobs/rubric-review-$stamp" -path '*/artifacts/app/verdicts.json' 2>/dev/null | head -1 || true)
if [ -n "$VERDICTS" ]; then
  mkdir -p results/rubric-check
  cp "$VERDICTS" results/rubric-check/verdicts.json
  python3 - "$VERDICTS" <<'PY'
import json, sys
doc = json.JSONDecoder().raw_decode(open(sys.argv[1]).read().lstrip())[0]
checks = doc.get("checks", doc)
from collections import Counter
outcomes = Counter((v.get("outcome") if isinstance(v, dict) else str(v)) for v in checks.values())
print("verdicts:", dict(outcomes))
for name, v in checks.items():
    if isinstance(v, dict) and v.get("outcome") not in ("pass", "not_applicable"):
        print("NON-PASS", name, ":", str(v.get("explanation", v))[:400])
PY
else
  echo "no verdicts.json produced; see jobs/rubric-review-$stamp"
fi

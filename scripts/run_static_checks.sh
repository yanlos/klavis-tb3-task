#!/bin/bash
# Co-authored by Claude (Anthropic) with the repository author.
# Run every TB3 static check against the task. Needs a clone of
# terminal-bench-3 at $TB3 and python3 >= 3.11 on PATH (for tomllib).
set -u
source "$(dirname "$0")/env.sh"
cd "$TB3" || { echo "clone terminal-bench-3 to $TB3 first"; exit 2; }
fails=0
for c in scripts/checks/check-*.sh; do
  if out=$(bash "$c" "$TASK" 2>&1); then
    echo "PASS $(basename "$c")"
  else
    fails=$((fails + 1))
    echo "FAIL $(basename "$c")"
    echo "$out" | grep -vE '^(Checking|PASS)' | sed 's/^/    /'
  fi
done
echo "static checks failed: $fails"
exit $fails

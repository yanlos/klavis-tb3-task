#!/bin/bash
# Run the verifier image directly against a candidate /app/ledger directory.
# This is the fast local loop that Harbor's oracle run also exercises.
#   scripts/run_probe.sh tasks/iap-ledger-rebuild/solution   # reference, expect reward 1
#   scripts/run_probe.sh scripts/cheat_probe                  # exploit probe, expect reward 0
# The candidate directory must contain a file named "rebuild". For the
# reference, a temporary copy of ledger_ref.py is used as rebuild.
set -eu
source "$(dirname "$0")/env.sh"
CAND="$(cd "$1" && pwd)"
IMG=iap-ledger-tests:dev
docker build -q -t "$IMG" "$TASK/tests" >/dev/null
STAGE="$HOME/.tb3-probe/$(basename "$CAND")-$$"
rm -rf "$STAGE" && mkdir -p "$STAGE"
if [ -f "$CAND/rebuild" ]; then
  cp "$CAND/rebuild" "$STAGE/rebuild"
elif [ -f "$CAND/ledger_ref.py" ]; then
  cp "$CAND/ledger_ref.py" "$STAGE/rebuild"
else
  echo "no rebuild or ledger_ref.py in $CAND"; exit 2
fi
chmod 755 "$STAGE/rebuild"
docker run --rm -v "$STAGE":/mnt/candidate:ro "$IMG" bash -c '
  rm -rf /app/ledger && cp -R /mnt/candidate /app/ledger
  bash /tests/test.sh > /tmp/test.out 2>&1
  echo "reward=$(cat /logs/verifier/reward.txt 2>/dev/null)"
  grep -E "passed|failed" /tmp/test.out | tail -1
'
rm -rf "$STAGE"

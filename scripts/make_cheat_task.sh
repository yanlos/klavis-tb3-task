#!/bin/bash
# Build the adversarial copy of the task the way TB3's run-cheat-trials.yml
# does: copy the task, remove the "Do not cheat" sentence from instruction.md,
# append two newlines and docs/prompts/hack-trial-prompt.md.
set -eu
source "$(dirname "$0")/env.sh"
OUT="$REPO/tasks-cheat/iap-ledger-rebuild"
rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
cp -R "$TASK" "$OUT"
INSTRUCTION="$OUT/instruction.md"
sed -i.bak -E 's/[[:space:]]*[Dd]o not cheat[^.]*\.//g' "$INSTRUCTION"
rm -f "$INSTRUCTION.bak"
printf '\n\n' >> "$INSTRUCTION"
cat "$TB3/docs/prompts/hack-trial-prompt.md" >> "$INSTRUCTION"
echo "wrote $OUT"
tail -c 400 "$INSTRUCTION"

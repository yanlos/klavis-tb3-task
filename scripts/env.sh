#!/bin/bash
# Source this file before you run the other scripts.
# It puts uv tools (harbor), Homebrew (docker, colima) and a Python 3.12 on PATH.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
# A shell opened from the Claude desktop app carries ANTHROPIC_BASE_URL. Harbor
# passes it into the agent container, where it breaks model lookup. Drop it.
unset ANTHROPIC_BASE_URL
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO
export TASK="$REPO/tasks/iap-ledger-rebuild"
export TB3="${TB3:-$HOME/Desktop/terminal-bench-3}"
# The TB3 static checks need python3 >= 3.11 for tomllib. macOS ships 3.9.
if [ ! -x "$REPO/.py312/bin/python3" ] && command -v uv >/dev/null 2>&1; then
  uv venv --python 3.12 "$REPO/.py312" >/dev/null 2>&1 || true
fi
if [ -x "$REPO/.py312/bin/python3" ]; then
  export PATH="$REPO/.py312/bin:$PATH"
fi

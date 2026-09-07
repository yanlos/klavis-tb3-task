#!/bin/bash
# Co-authored by Claude (Anthropic) with the repository author.
# Oracle and nop validation with the docker backend. Oracle must score 1.0.
# Nop must score 0.0.
set -u
source "$(dirname "$0")/env.sh"
cd "$REPO"
harbor run -p tasks/iap-ledger-rebuild --agent oracle --env docker --yes -o jobs --job-name validate-oracle
harbor run -p tasks/iap-ledger-rebuild --agent nop    --env docker --yes -o jobs --job-name validate-nop

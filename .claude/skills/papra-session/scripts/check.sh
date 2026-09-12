#!/usr/bin/env bash
# Format, lint, typecheck and test. Run before every commit that touches code.
# Usage: check.sh [vitest path filters...]   e.g. check.sh src/modules/receipt-extraction
# With no filters runs all server unit tests (skips *.int.test.ts).
set -euo pipefail
DIR="${PAPRA_DIR:-$(git rev-parse --show-toplevel)}"
POLYFILL="${TMPDIR:-/tmp}/temporal-polyfill/setup.mjs"

cd "$DIR"
CHANGED=$( { git diff --name-only --diff-filter=ACMR origin/main...HEAD; git diff --name-only --diff-filter=ACMR; git ls-files --others --exclude-standard; } \
  | grep -E '\.(ts|tsx)$' | sort -u || true)

if [ -n "$CHANGED" ]; then
  echo "==> oxfmt + oxlint on changed files"
  echo "$CHANGED" | xargs npx oxfmt >/dev/null
  echo "$CHANGED" | xargs npx oxlint -c oxlint.config.ts
fi

cd apps/papra-server
echo "==> Typecheck server"
npx tsc --noEmit -p .

echo "==> Tests"
NODE_OPTS=""
if [ -f "$POLYFILL" ]; then NODE_OPTS="--import $POLYFILL"; fi
if [ $# -gt 0 ]; then
  NODE_OPTIONS="$NODE_OPTS" npx vitest run "$@"
else
  NODE_OPTIONS="$NODE_OPTS" npx vitest run --exclude '**/*.int.test.ts'
fi

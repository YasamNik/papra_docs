#!/usr/bin/env bash
# Set up the papra_docs workspace. Safe to re-run.
# Usage: start_session.sh [branch]
#   branch defaults to the most recently updated non-main branch on origin.
# Env: PAPRA_DIR (defaults to the current checkout), PAPRA_REPO, GH_TOKEN (clone fallback only)
set -euo pipefail

REPO="${PAPRA_REPO:-YasamNik/papra_docs}"
BRANCH="${1:-}"
POLYFILL_DIR="${TMPDIR:-/tmp}/temporal-polyfill"

# Normal case: already running inside the checkout (Claude Code on a local clone).
# Fallback: no checkout around, so clone one.
if [ -n "${PAPRA_DIR:-}" ]; then
  DIR="$PAPRA_DIR"
elif DIR=$(git rev-parse --show-toplevel 2>/dev/null); then
  :
else
  DIR="$HOME/work/papra"
fi

if [ -d "$DIR/.git" ]; then
  echo "==> Using existing checkout at $DIR"
  cd "$DIR"
  git fetch -q --prune origin || echo "    (fetch failed, continuing offline)"
else
  echo "==> Cloning $REPO into $DIR"
  mkdir -p "$(dirname "$DIR")"
  git clone -q "https://github.com/$REPO.git" "$DIR"
  cd "$DIR"
fi

# Only set a local identity if the machine has no global one configured.
git config user.name >/dev/null 2>&1 || git config user.name "${GIT_AUTHOR_NAME:-YasamNik}"
git config user.email >/dev/null 2>&1 || git config user.email "${GIT_AUTHOR_EMAIL:-yasam.nikros@gmail.com}"

if [ -z "$BRANCH" ]; then
  BRANCH=$(git for-each-ref --sort=-committerdate refs/remotes/origin --format='%(refname:lstrip=3)' \
    | grep -vxE 'HEAD|main|master' | head -1 || true)
fi

if [ -n "$BRANCH" ]; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "==> Uncommitted changes present, staying on $(git branch --show-current)"
  elif git show-ref -q --verify "refs/remotes/origin/$BRANCH"; then
    if git show-ref -q --verify "refs/heads/$BRANCH" && git merge-base --is-ancestor "origin/$BRANCH" "$BRANCH"; then
      git checkout -q "$BRANCH"
    else
      git checkout -q -B "$BRANCH" "origin/$BRANCH"
    fi
  elif git show-ref -q --verify "refs/heads/$BRANCH"; then
    git checkout -q "$BRANCH"
  else
    echo "==> Branch $BRANCH not found, creating it from main"
    git checkout -q -B "$BRANCH" origin/main
  fi
else
  echo "==> No feature branch on origin, staying on main. Create one before committing."
fi

echo "==> Installing dependencies"
PNPM_VERSION=$(node -p "(require('./package.json').packageManager||'pnpm@latest').split('@')[1]")
if ! command -v pnpm >/dev/null || [ "$(pnpm -v)" != "$PNPM_VERSION" ]; then
  npm i -g "pnpm@$PNPM_VERSION" >/dev/null 2>&1 || echo "    (could not install pnpm@$PNPM_VERSION globally)"
fi
pnpm install --ignore-scripts >"${TMPDIR:-/tmp}/papra-install.log" 2>&1 \
  || { tail -20 "${TMPDIR:-/tmp}/papra-install.log"; exit 1; }

echo "==> Building workspace packages"
pnpm --filter "./packages/*" run build >"${TMPDIR:-/tmp}/papra-build.log" 2>&1 \
  || { tail -20 "${TMPDIR:-/tmp}/papra-build.log"; exit 1; }

# Repo targets Node 26 (global Temporal). Older Node needs a polyfill for tests.
if [ "$(node -e 'process.stdout.write(typeof Temporal)')" = "undefined" ] && [ ! -f "$POLYFILL_DIR/setup.mjs" ]; then
  echo "==> Node $(node -v) lacks Temporal, installing test polyfill"
  mkdir -p "$POLYFILL_DIR"
  (cd "$POLYFILL_DIR" && npm init -y >/dev/null && npm i temporal-polyfill >/dev/null 2>&1)
  echo "import 'temporal-polyfill/global';" > "$POLYFILL_DIR/setup.mjs"
fi

echo
echo "==> Ready: $DIR on branch $(git branch --show-current)"
git log --oneline -5
echo
echo "==> Latest WORKLOG entry"
if [ -f WORKLOG.md ]; then
  awk '/^## /{n++} n==1' WORKLOG.md
else
  echo "(no WORKLOG.md on this branch yet)"
fi

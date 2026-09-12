#!/usr/bin/env bash
# Push the current feature branch to GitHub. Run after the WORKLOG.md entry is committed.
# Usage: GH_TOKEN=... end_session.sh
set -euo pipefail
REPO="${PAPRA_REPO:-YasamNik/papra_docs}"
DIR="${PAPRA_DIR:-$(git rev-parse --show-toplevel)}"

cd "$DIR"
BRANCH=$(git branch --show-current)

case "$BRANCH" in
  main|master|"") echo "Refusing to push '$BRANCH'. Work on a feature branch and merge via PR."; exit 1 ;;
esac
if [ -n "$(git status --porcelain)" ]; then
  echo "Uncommitted changes, commit or discard first:"; git status --short; exit 1
fi
if ! git diff --name-only "origin/$BRANCH"...HEAD 2>/dev/null | grep -qx WORKLOG.md \
   && ! git diff --name-only origin/main...HEAD | grep -qx WORKLOG.md; then
  echo "Warning: WORKLOG.md has no new entry in this push. Add one before ending the session."
fi

# Locally, git is already authenticated (SSH key, credential helper or gh).
# GH_TOKEN is only a fallback for environments without stored credentials.
if [ -n "${GH_TOKEN:-}" ]; then
  AUTH="Authorization: Basic $(printf 'x-access-token:%s' "$GH_TOKEN" | base64 | tr -d '\n')"
  git -c http.extraHeader="$AUTH" push -q -u origin "$BRANCH"
  git -c http.extraHeader="$AUTH" fetch -q origin "$BRANCH"
else
  git push -q -u origin "$BRANCH"
  git fetch -q origin "$BRANCH"
fi

if [ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$BRANCH")" ]; then
  echo "==> Pushed $BRANCH ($(git rev-parse --short HEAD))"
  echo "==> PR: https://github.com/$REPO/compare/main...$BRANCH?expand=1"
else
  echo "Push did not land. Check your git credentials, or token scope: Contents read and write on $REPO."; exit 1
fi

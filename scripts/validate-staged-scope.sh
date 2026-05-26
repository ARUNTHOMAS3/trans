#!/usr/bin/env sh
set -eu

# Strict commit scope guard
# Override (maintainers only): ALLOW_BROAD_COMMIT=1 git commit ...

STAGED_FILES=$(git diff --cached --name-only)
[ -z "$STAGED_FILES" ] && exit 0

COUNT=$(printf '%s\n' "$STAGED_FILES" | sed '/^$/d' | wc -l | tr -d ' ')
MAX_FILES=25

if [ "$COUNT" -gt "$MAX_FILES" ] && [ "${ALLOW_BROAD_COMMIT:-0}" != "1" ]; then
  echo "Commit blocked: $COUNT staged files exceeds focused limit ($MAX_FILES)."
  echo "Commit only task-specific files, or split into smaller commits."
  echo "Maintainer override: ALLOW_BROAD_COMMIT=1 git commit ..."
  exit 1
fi

if printf '%s\n' "$STAGED_FILES" | grep -Eq '^node_modules/|/node_modules/'; then
  echo "Commit blocked: node_modules files are staged."
  echo "Remove them from staging (git reset HEAD <path>) and retry."
  exit 1
fi

echo "Staged scope check passed: $COUNT file(s)."

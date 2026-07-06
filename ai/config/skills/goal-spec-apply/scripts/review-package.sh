#!/usr/bin/env bash
# Write a review package (commit list + stat + full diff) for BASE..HEAD to a file.
# Usage: review-package.sh <BASE> <HEAD> [out-file]
# Prints the out-file path on success.
set -euo pipefail
BASE="${1:-}"
HEAD="${2:-HEAD}"
[ -z "$BASE" ] && { echo "Usage: review-package.sh <BASE> <HEAD> [out-file]"; exit 1; }
out="${3:-$(mktemp -t review-package.XXXXXX)}"

mkdir -p "$(dirname "$out")"
{
  echo "# Review package: ${BASE}..${HEAD}"
  echo
  echo "## Commits"
  git log --oneline "${BASE}..${HEAD}" 2>/dev/null || echo "(no commits in range)"
  echo
  echo "## Diff stat"
  git diff --stat "${BASE}..${HEAD}" 2>/dev/null || echo "(empty)"
  echo
  echo "## Full diff"
  git diff -U10 "${BASE}..${HEAD}" 2>/dev/null || echo "(empty)"
} > "$out"
echo "$out"

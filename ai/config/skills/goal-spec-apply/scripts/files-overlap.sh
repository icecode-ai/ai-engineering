#!/usr/bin/env bash
# Check whether two file-lists share any path. Used by the controller to decide whether
# independent tasks can run in the same parallel wave (their planned/actual files must be
# disjoint), and whether a fix for a failed task conflicts with a sibling's already-produced files.
#
# Usage: files-overlap.sh <files-A> <files-B>
#   Exit 0 — prints "NO OVERLAP"
#   Exit 1 — prints "OVERLAP:" then the shared paths (one per line)
#   Exit 2 — usage / missing-file error
set -euo pipefail
a="${1:-}"; b="${2:-}"
{ [ -z "$a" ] || [ -z "$b" ]; } && { echo "Usage: files-overlap.sh <files-A> <files-B>"; exit 2; }
[ -f "$a" ] || { echo "file-list A not found: $a"; exit 2; }
[ -f "$b" ] || { echo "file-list B not found: $b"; exit 2; }

# Normalize each list: trim leading/trailing whitespace, drop blanks, dedup.
norm() { sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$1" | grep -v '^$' | sort -u; }

overlap=$(comm -12 <(norm "$a") <(norm "$b") || true)
if [ -n "$overlap" ]; then
  echo "OVERLAP:"
  printf '%s\n' "$overlap"
  exit 1
fi
echo "NO OVERLAP"
exit 0

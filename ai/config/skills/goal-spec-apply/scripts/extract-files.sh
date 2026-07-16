#!/usr/bin/env bash
# Extract changed-file paths from an implementer report into a one-path-per-line list,
# so the controller does not hand-transcribe paths (which can silently drop files).
# Tolerant of common report phrasings: "Created: path", "Modified: path",
# "- `path`", or a bare path on its own line.
#
# Usage: extract-files.sh <report-file> <out-file>
#   Exit 0 — wrote N paths to <out-file>.
#   Exit 2 — no paths could be extracted; <out-file> is emptied and the controller
#            must fill it manually from the report.
set -euo pipefail
report="${1:-}"
out="${2:-}"
{ [ -z "$report" ] || [ -z "$out" ]; } && { echo "Usage: extract-files.sh <report-file> <out-file>"; exit 1; }
[ -f "$report" ] || { echo "report not found: $report"; exit 1; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Strip bullets, common labels, backticks, and surrounding whitespace. Keep only
# single-token lines that look like paths (absolute, or containing a slash).
sed -E \
  -e 's/^[[:space:]]*[-*][[:space:]]+//' \
  -e 's/^(Created|Modified|Updated|Changed|Deleted|Renamed|Renames|Create|Modify|Update|Delete|Tested|Test|Added|Removed|Moved)[[:space:]]*:[[:space:]]*//' \
  -e 's/`//g' \
  -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  "$report" \
  | grep -E '(^/|/)' \
  | grep -vE '[[:space:]]' \
  > "$tmp" || true

# Deduplicate, preserving first-seen order.
awk '!seen[$0]++' "$tmp" > "$out"

count=$(wc -l < "$out" | tr -d ' ')
if [ "${count:-0}" -eq 0 ]; then
  : > "$out"
  echo "WARN: no file paths extracted from $report — fill $out manually from the report." >&2
  exit 2
fi
echo "$out ($count files)"

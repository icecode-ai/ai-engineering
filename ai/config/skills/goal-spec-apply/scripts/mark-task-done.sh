#!/usr/bin/env bash
# Mark every unchecked checkbox within Task N's block as done.
# A task block starts at "### Task N:" and ends at the next "### Task " or "## " header (or EOF).
# Headers appearing inside ``` code fences are ignored so a "## " line in an example block
# does not prematurely end the block.
# Usage: mark-task-done.sh <tasks-file> <task-number>
set -euo pipefail
tasks_file="${1:-}"
n="${2:-}"
{ [ -z "$tasks_file" ] || [ -z "$n" ]; } && { echo "Usage: mark-task-done.sh <tasks-file> <task-number>"; exit 1; }
[ -f "$tasks_file" ] || { echo "tasks-file not found: $tasks_file"; exit 1; }

start=$(awk -v n="$n" '
  BEGIN { infence=0 }
  /^```/ { infence=!infence; next }
  infence { next }
  $0 ~ "^### Task " n ":" { print NR; exit }
' "$tasks_file") || true
if [ -z "$start" ]; then
  echo "Task ${n} not found in $tasks_file" >&2
  exit 1
fi

# Find the next "### Task " or "## " header after $start, skipping lines inside ``` fences
end=$(awk -v s="$start" '
  BEGIN { infence=0 }
  NR<=s { next }
  /^```/ { infence=!infence; next }
  infence { next }
  /^(### Task |## )/ { print NR; exit }
' "$tasks_file") || true
if [ -z "$end" ]; then
  end=$(wc -l < "$tasks_file")
else
  end=$((end - 1))
fi

# Mark `[ ]` -> `[x]` only within [start,end] AND outside ``` fences. sed would
# blindly touch fenced example checkboxes / code; awk stays fence-aware like the
# block-boundary detection above. Write to a temp then move (safer than in-place).
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
awk -v s="$start" -v e="$end" '
  BEGIN { infence=0 }
  /^```/ { infence=!infence; print; next }
  infence { print; next }
  (NR>=s && NR<=e) { gsub(/\[ \]/, "[x]"); print; next }
  { print }
' "$tasks_file" > "$tmp" && mv "$tmp" "$tasks_file"
echo "Task ${n}: all steps marked complete in $tasks_file"

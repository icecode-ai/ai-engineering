#!/usr/bin/env bash
# Extract a single task's full text from tasks.md to a brief file.
# A task block starts at "### Task <N>:" and ends at the next "### Task " or "## " header (or EOF).
# Headers appearing inside ``` code fences are ignored so a "## " line in an example block
# does not prematurely terminate the brief.
# Usage: task-brief.sh <tasks-file> <task-number> [out-file]
# Prints the out-file path on success.
set -euo pipefail
tasks_file="${1:-}"
n="${2:-}"
{ [ -z "$tasks_file" ] || [ -z "$n" ]; } && { echo "Usage: task-brief.sh <tasks-file> <task-number> [out-file]"; exit 1; }
[ -f "$tasks_file" ] || { echo "tasks-file not found: $tasks_file"; exit 1; }
out="${3:-/dev/stdout}"

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

if [ "$out" = "/dev/stdout" ]; then
  sed -n "${start},${end}p" "$tasks_file"
else
  mkdir -p "$(dirname "$out")"
  sed -n "${start},${end}p" "$tasks_file" > "$out"
  echo "$out"
fi

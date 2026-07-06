#!/usr/bin/env bash
# Extract a single task's full text from tasks.md to a brief file.
# A task block starts at "### Task <N>:" and ends at the next "### Task " or "## " header (or EOF).
# Usage: task-brief.sh <tasks-file> <task-number> [out-file]
# Prints the out-file path on success.
set -euo pipefail
tasks_file="${1:-}"
n="${2:-}"
{ [ -z "$tasks_file" ] || [ -z "$n" ]; } && { echo "Usage: task-brief.sh <tasks-file> <task-number> [out-file]"; exit 1; }
[ -f "$tasks_file" ] || { echo "tasks-file not found: $tasks_file"; exit 1; }
out="${3:-/dev/stdout}"

start=$(grep -nE "^### Task ${n}:" "$tasks_file" | head -1 | cut -d: -f1) || true
if [ -z "$start" ]; then
  echo "Task ${n} not found in $tasks_file" >&2
  exit 1
fi

# Find the next "### Task " or "## " header after $start
end=$(awk -v s="$start" 'NR>s && /^(### Task |## )/{print NR; exit}' "$tasks_file") || true
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

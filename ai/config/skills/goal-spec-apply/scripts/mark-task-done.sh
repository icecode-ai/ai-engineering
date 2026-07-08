#!/usr/bin/env bash
# Mark every unchecked checkbox within Task N's block as done.
# A task block starts at "### Task N:" and ends at the next "### Task " or "## " header (or EOF).
# Usage: mark-task-done.sh <tasks-file> <task-number>
set -euo pipefail
tasks_file="${1:-}"
n="${2:-}"
{ [ -z "$tasks_file" ] || [ -z "$n" ]; } && { echo "Usage: mark-task-done.sh <tasks-file> <task-number>"; exit 1; }
[ -f "$tasks_file" ] || { echo "tasks-file not found: $tasks_file"; exit 1; }

start=$(grep -nE "^### Task ${n}:" "$tasks_file" | head -1 | cut -d: -f1) || true
if [ -z "$start" ]; then
  echo "Task ${n} not found in $tasks_file" >&2
  exit 1
fi

end=$(awk -v s="$start" 'NR>s && /^(### Task |## )/{print NR; exit}' "$tasks_file") || true
if [ -z "$end" ]; then
  end=$(wc -l < "$tasks_file")
else
  end=$((end - 1))
fi

sed -i.bak "${start},${end}s/\[ \]/[x]/" "$tasks_file" && rm -f "$tasks_file.bak"
echo "Task ${n}: all steps marked complete in $tasks_file"

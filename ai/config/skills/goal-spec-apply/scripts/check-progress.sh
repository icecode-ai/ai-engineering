#!/usr/bin/env bash
# Show task progress from a change's tasks.md.
# Usage: check-progress.sh <change-name>
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: check-progress.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

tasks_file="${PROJECT_ROOT}/ai/output/changes/$name/tasks.md"
if [ ! -f "$tasks_file" ]; then
  echo "No tasks.md found for change '$name'"
  exit 1
fi
total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
pending=$((total - done_count))
echo "Progress: $done_count/$total tasks complete ($pending remaining)"

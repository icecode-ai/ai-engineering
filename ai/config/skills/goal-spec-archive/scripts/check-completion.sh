#!/usr/bin/env bash
# Check artifact + task completion status for a change.
# Usage: check-completion.sh <change-name>
# Prints INCOMPLETE or COMPLETE on the last line.
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: check-completion.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
[ -d "$change_dir" ] || { echo "Change '$name' not found."; exit 1; }

incomplete=false
for artifact in proposal.md design.md tasks.md; do
  if [ ! -f "$change_dir/$artifact" ]; then echo "✗ $artifact (missing)"; incomplete=true; fi
done
specs_dir="$change_dir/specs"
if [ ! -d "$specs_dir" ] || [ -z "$(ls -A "$specs_dir" 2>/dev/null)" ]; then
  echo "⚠ specs/ (missing — no delta specs to sync)"
  incomplete=true
fi
tasks_file="$change_dir/tasks.md"
if [ -f "$tasks_file" ]; then
  total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
  done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
  pending=$((total - done_count))
  if [ "$pending" -gt 0 ]; then echo "⚠ $pending tasks still incomplete."; incomplete=true; fi
fi
[ "$incomplete" = true ] && echo "INCOMPLETE" || echo "COMPLETE"

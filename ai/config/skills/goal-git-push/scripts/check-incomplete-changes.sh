#!/usr/bin/env bash
# Check ai/output/changes/ for incomplete tasks or missing artifacts before pushing MAIN.
# Exits 1 if any active (non-archived) change is incomplete; prints warnings.
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

changes_dir="${PROJECT_ROOT}/ai/output/changes"
has_incomplete=false

for change in "$changes_dir"/*/; do
  [ -d "$change" ] || continue
  change_name="$(basename "$change")"
  [ "$change_name" = "archive" ] && continue

  tasks_file="${change}tasks.md"
  if [ -f "$tasks_file" ]; then
    total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
    done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
    pending=$((total - done_count))
    if [ "$pending" -gt 0 ]; then
      echo "⚠ Change '$change_name' has $pending incomplete task(s)"
      has_incomplete=true
    fi
  else
    echo "⚠ Change '$change_name' is missing tasks.md"
    has_incomplete=true
  fi

  for artifact in proposal.md design.md tasks.md; do
    if [ ! -f "${change}${artifact}" ]; then
      echo "⚠ Change '$change_name' is missing $artifact"
      has_incomplete=true
    fi
  done
done

active_count=$(ls -1d "$changes_dir"/*/ 2>/dev/null | grep -v '/archive/$' | wc -l | tr -d ' ') || active_count=0
if [ "$active_count" -gt 0 ]; then
  echo "Found $active_count active (unarchived) change(s) in ai/output/changes/"
fi

if [ "$has_incomplete" = true ]; then
  echo ""
  echo "❌ Cannot push: there are incomplete tasks or missing artifacts in active changes."
  echo "Please complete the tasks or archive the changes first:"
  echo "  - Run /ai-spec-apply <change-name> to finish pending tasks"
  echo "  - Run /ai-spec-archive <change-name> to archive completed changes"
  exit 1
fi

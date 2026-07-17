#!/usr/bin/env bash
# Check/show artifact status for a spec change.
# Usage: check-artifacts.sh <change-name>
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: check-artifacts.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
[ -d "$change_dir" ] || { echo "Change '$name' not found."; exit 1; }

echo "=== Change: $name ==="
all_done=true
for artifact in proposal.md design.md tasks.md; do
  if [ -f "$change_dir/$artifact" ]; then
    echo "✓ $artifact"
  else
    echo "✗ $artifact (missing)"
    all_done=false
  fi
done
specs_dir="$change_dir/specs"
if [ -d "$specs_dir" ] && [ "$(ls -A "$specs_dir" 2>/dev/null)" ]; then
  echo "✓ specs/"
else
  echo "○ specs/ (empty — may need creation)"
fi
# Emit an explicit state the controller branches on (step 2 of the skill).
if [ "$all_done" = false ]; then
  echo "Some artifacts are missing. Suggest running /ai-spec-propose $name first."
  echo "STATE: BLOCKED"
  exit 0
fi

# Artifacts present — check task completion to tell "all done" from "in progress".
# Fence-aware walk (same logic as check-progress.sh): a task is complete when it
# has no pending `- [ ]` step. completed==total (and total>0) means ALL_DONE.
tasks_file="$change_dir/tasks.md"
read total_tasks completed_tasks total_steps done_steps <<EOF
$(awk '
  BEGIN { infence=0; intask=0; tt=0; ct=0; ts=0; ds=0; pend=0 }
  /^```/ { infence=!infence; next }
  infence { next }
  /^### Task [0-9]+/ { if (intask) { if (pend==0) ct++ }; intask=1; pend=0; tt++; next }
  /^(## )/            { if (intask) { if (pend==0) ct++ }; intask=0; pend=0; next }
  intask && /^[[:space:]]*[-*][[:space:]]+\[ \]/ { ts++; pend++ }
  intask && /^[[:space:]]*[-*][[:space:]]+\[[xX]\]/ { ts++; ds++ }
  END { if (intask && pend==0) ct++; print tt+0, ct+0, ts+0, ds+0 }
' "$tasks_file")
EOF

if [ "$total_tasks" -gt 0 ] && [ "$completed_tasks" -eq "$total_tasks" ]; then
  echo "Progress: $completed_tasks/$total_tasks tasks complete."
  echo "STATE: ALL_DONE"
  echo "All tasks complete. Suggest running /ai-spec-archive $name."
else
  echo "Progress: $completed_tasks/$total_tasks tasks complete; $((total_tasks - completed_tasks)) remaining."
  echo "STATE: IN_PROGRESS"
fi

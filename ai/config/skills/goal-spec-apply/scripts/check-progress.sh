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
# Walk the file fence-aware: count task blocks ("### Task N:") and step checkboxes
# (done + total), ignoring any lines inside ``` code fences so example checkboxes
# are not mistaken for real steps.
read total_tasks completed_tasks total_steps done_steps <<EOF
$(awk '
  BEGIN { infence=0; intask=0; tt=0; ct=0; ts=0; ds=0; pend=0 }
  /^```/ { infence=!infence; next }
  infence { next }
  /^### Task [0-9]+/ {
    if (intask) { if (pend==0) ct++; }
    intask=1; pend=0; tt++; next
  }
  /^(## )/ {
    if (intask) { if (pend==0) ct++; }
    intask=0; pend=0; next
  }
  intask && /^[[:space:]]*[-*][[:space:]]+\[ \]/ { ts++; pend++ }
  intask && /^[[:space:]]*[-*][[:space:]]+\[x\]/  { ts++; ds++ }
  END {
    if (intask && pend==0) ct++
    print tt+0, ct+0, ts+0, ds+0
  }
' "$tasks_file")
EOF
pending_steps=$((total_steps - done_steps))
echo "Progress: $completed_tasks/$total_tasks tasks complete; $done_steps/$total_steps steps done ($pending_steps steps remaining)"

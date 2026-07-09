#!/usr/bin/env bash
# Record the BASE commit (current HEAD) for a task's review range.
# Usage: record-base.sh <change_dir> <task_number>
#   <change_dir> — path relative to workspace root, e.g. ai/output/changes/<name>
# Writes <change_dir>/sdd/task-<N>-base.sha and echoes the SHA for the caller to capture.
set -euo pipefail
change_dir="${1:-}"
N="${2:-}"
if [ -z "$change_dir" ] || [ -z "$N" ]; then
  echo "Usage: record-base.sh <change_dir> <task_number>"
  exit 1
fi

base="$(git rev-parse HEAD)"
mkdir -p "${change_dir}/sdd"
echo "$base" > "${change_dir}/sdd/task-${N}-base.sha"
echo "$base"

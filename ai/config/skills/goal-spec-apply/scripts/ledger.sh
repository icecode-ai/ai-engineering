#!/usr/bin/env bash
# Progress ledger for subagent-driven apply. Resists context compaction.
# Usage:
#   ledger.sh init   <change-dir>                     # create sdd/ dir + empty progress.md
#   ledger.sh append <change-dir> <line>              # append a line to progress.md
#   ledger.sh append-task <change-dir> <task-num> <BASE-sha>  # append a "task complete" line with short SHA range
#   ledger.sh read   <change-dir>                     # print progress.md (or "(no ledger yet)")
set -euo pipefail
cmd="${1:-}"
change_dir="${2:-}"
[ -n "$cmd" ] && [ -n "$change_dir" ] || { echo "Usage: ledger.sh <init|append|append-task|read> <change-dir> [line|task-num BASE-sha]"; exit 1; }
ledger_file="${change_dir}/sdd/progress.md"

case "$cmd" in
  init)
    mkdir -p "${change_dir}/sdd"
    [ -f "$ledger_file" ] || printf '# Progress ledger (subagent-driven apply)\n' > "$ledger_file"
    echo "$ledger_file"
    ;;
  append)
    line="${3:-}"
    [ -n "$line" ] || { echo "append requires a line"; exit 1; }
    mkdir -p "${change_dir}/sdd"
    printf '%s\n' "$line" >> "$ledger_file"
    echo "appended to $ledger_file"
    ;;
  append-task)
    N="${3:-}"
    BASE="${4:-}"
    { [ -z "$N" ] || [ -z "$BASE" ]; } && { echo "append-task requires <change-dir> <task-number> <BASE-sha>"; exit 1; }
    mkdir -p "${change_dir}/sdd"
    HEAD7="$(git rev-parse --short HEAD)"
    BASE7="$(git rev-parse --short "$BASE")"
    printf 'Task %s: complete (commits %s..%s, review clean)\n' "$N" "$BASE7" "$HEAD7" >> "$ledger_file"
    echo "appended to $ledger_file"
    ;;
  read)
    if [ -f "$ledger_file" ]; then cat "$ledger_file"; else echo "(no ledger yet)"; fi
    ;;
  *)
    echo "Unknown command: $cmd"; exit 1
    ;;
esac

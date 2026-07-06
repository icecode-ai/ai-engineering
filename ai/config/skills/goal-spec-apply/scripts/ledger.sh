#!/usr/bin/env bash
# Progress ledger for subagent-driven apply. Resists context compaction.
# Usage:
#   ledger.sh init   <change-dir>                     # create sdd/ dir + empty progress.md
#   ledger.sh append <change-dir> <line>              # append a line to progress.md
#   ledger.sh read   <change-dir>                     # print progress.md (or "(no ledger yet)")
set -euo pipefail
cmd="${1:-}"
change_dir="${2:-}"
[ -n "$cmd" ] && [ -n "$change_dir" ] || { echo "Usage: ledger.sh <init|append|read> <change-dir> [line]"; exit 1; }
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
  read)
    if [ -f "$ledger_file" ]; then cat "$ledger_file"; else echo "(no ledger yet)"; fi
    ;;
  *)
    echo "Unknown command: $cmd"; exit 1
    ;;
esac

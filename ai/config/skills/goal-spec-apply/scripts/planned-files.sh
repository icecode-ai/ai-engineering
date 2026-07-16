#!/usr/bin/env bash
# Extract a task's planned file paths from its **Files:** block in tasks.md.
# Strips backticks and trailing :line-range suffixes (e.g. path:123-145) so two
# tasks editing the same file at different line ranges still count as overlapping.
# Used by the controller to form a parallel batch with disjoint file sets BEFORE
# dispatch — at that point actual files don't exist yet, so extract-files.sh
# (which reads an implementer report) cannot run.
#
# Usage: planned-files.sh <tasks-file> <task-number> [out-file]
#   Prints the out-file path on success (or the paths to stdout if no out-file).
set -euo pipefail
tasks_file="${1:-}"
n="${2:-}"
{ [ -z "$tasks_file" ] || [ -z "$n" ]; } && { echo "Usage: planned-files.sh <tasks-file> <task-number> [out-file]"; exit 1; }
[ -f "$tasks_file" ] || { echo "tasks-file not found: $tasks_file"; exit 1; }
out="${3:-/dev/stdout}"

# Walk the file fence-aware: locate task N's block (### Task N: ... up to the next
# ### Task or ## header, skipping ``` fences), then within it read the **Files:**
# block (up to the next ** bold header) and pull out the paths.
paths="$(awk -v n="$n" '
  BEGIN { infence=0; intask=0; infiles=0 }
  /^```/ { infence=!infence; next }
  infence { next }
  $0 ~ "^### Task " n ":" { intask=1; infiles=0; next }
  intask && /^(### Task |## )/ { intask=0; infiles=0; next }
  intask {
    if ($0 ~ /^\*\*Files:\*\*/) { infiles=1; next }
    if (infiles && $0 ~ /^\*\*/) { infiles=0; next }
    if (infiles) {
      line = $0
      sub(/^[[:space:]]*[-*][[:space:]]+/, "", line)
      sub(/^(Created|Modified|Updated|Changed|Deleted|Renamed|Renames|Create|Modify|Update|Delete|Tested|Test|Added|Removed|Moved)[[:space:]]*:[[:space:]]*/, "", line)
      gsub(/`/, "", line)
      sub(/:[0-9]+(-[0-9]+)?$/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line != "") print line
    }
  }
' "$tasks_file" | awk '!seen[$0]++')" || true

if [ "$out" = "/dev/stdout" ]; then
  [ -n "$paths" ] && printf '%s\n' "$paths"
else
  mkdir -p "$(dirname "$out")"
  if [ -n "$paths" ]; then printf '%s\n' "$paths" > "$out"; else : > "$out"; fi
  echo "$out"
fi

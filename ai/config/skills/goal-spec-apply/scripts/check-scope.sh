#!/usr/bin/env bash
# Check whether each planned file in a file-list falls under at least one
# allowed edit root (produced by edit-roots.sh). A file is in scope if it equals
# a root or starts with "<root>/". Out-of-scope files are a pre-flight scope
# finding — the controller batches them into the step-6 question alongside
# conflict findings (the user decides; nothing is auto-blocked).
#
# Usage: check-scope.sh <planned-files> <roots>
#   Exit 0 — all files in scope (prints "IN SCOPE")
#   Exit 1 — some files out of scope (prints "OUT OF SCOPE:" then the files)
#   Exit 2 — usage / missing-file error, OR no roots declared (prints "NO ROOTS"
#            — the controller reports the change as unscoped and asks the user)
set -euo pipefail
files="${1:-}"; roots="${2:-}"
{ [ -z "$files" ] || [ -z "$roots" ]; } && { echo "Usage: check-scope.sh <planned-files> <roots>"; exit 2; }
[ -f "$files" ] || { echo "planned-files not found: $files"; exit 2; }
[ -f "$roots" ] || { echo "roots not found: $roots"; exit 2; }
[ -s "$roots" ] || { echo "NO ROOTS"; exit 2; }

out_of_scope="$(awk '
  NR==FNR { if ($0 != "") roots[$0]=1; next }
  {
    f=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",f); if (f=="") next
    in_scope=0
    for (r in roots) {
      if (f==r || index(f, r "/")==1) { in_scope=1; break }
    }
    if (!in_scope) print f
  }
' "$roots" "$files" || true)"

if [ -n "$out_of_scope" ]; then
  echo "OUT OF SCOPE:"
  printf '%s\n' "$out_of_scope"
  exit 1
fi
echo "IN SCOPE"
exit 0

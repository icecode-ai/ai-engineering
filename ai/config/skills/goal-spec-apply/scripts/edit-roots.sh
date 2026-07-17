#!/usr/bin/env bash
# Extract the allowed edit roots for a change from its proposal.md.
# Scans the whole proposal for backtick-quoted module/path tokens (e.g.
# `modules/auth`, `modules/api/src`, `ai`) and normalizes them to module-level
# roots: a `modules/<x>/...` token becomes `modules/<x>`; an `ai`/`ai/...` token
# becomes `ai`. The controller uses these roots (via check-scope.sh) to flag
# tasks whose planned files fall outside the change's declared affected scope —
# a pre-flight scope finding surfaced alongside the step-6 conflict scan.
#
# Robust by design: it does NOT require a formal `### Affected Modules` block —
# any `modules/<x>` / `ai` mention anywhere in proposal.md counts, so it works
# with the loosely-templated `## Impact` section goal-spec-propose produces.
# Root-level files (package.json, tsconfig.json, …) are intentionally NOT roots:
# a task editing one surfaces as an out-of-scope finding for the user to decide.
#
# Usage: edit-roots.sh <proposal.md> [out-file]
#   Prints roots one per line (and the out-file path if out-file given).
#   Exit 0 — at least one root found.
#   Exit 2 — no roots found (change is unscoped; the controller reports it).
set -euo pipefail
proposal="${1:-}"
[ -n "$proposal" ] || { echo "Usage: edit-roots.sh <proposal.md> [out-file]"; exit 2; }
[ -f "$proposal" ] || { echo "proposal not found: $proposal"; exit 2; }
out="${2:-/dev/stdout}"

roots="$(awk '
  {
    line = $0
    while (match(line, /`[^`]+`/)) {
      tok = substr(line, RSTART+1, RLENGTH-2)
      line = substr(line, RSTART+RLENGTH)
      if (tok ~ /^modules\/[^\/]+/) {
        split(tok, parts, "/")
        print "modules/" parts[2]
      } else if (tok == "ai" || tok ~ /^ai\//) {
        print "ai"
      }
    }
  }
' "$proposal" | sort -u)" || true

if [ "$out" = "/dev/stdout" ]; then
  [ -n "$roots" ] && printf '%s\n' "$roots"
else
  mkdir -p "$(dirname "$out")"
  if [ -n "$roots" ]; then printf '%s\n' "$roots" > "$out"; else : > "$out"; fi
  echo "$out"
fi

[ -n "$roots" ] || exit 2

#!/usr/bin/env bash
# Assess delta specs in a change: list capabilities, whether the main spec exists,
# and a per-capability operation count (ADDED/MODIFIED/REMOVED/RENAMED requirement blocks).
# Usage: assess-delta-specs.sh <change-name>
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: assess-delta-specs.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
delta_specs_dir="$change_dir/specs"
if [ -d "$delta_specs_dir" ] && [ "$(ls -A "$delta_specs_dir" 2>/dev/null)" ]; then
  echo "=== Delta specs found ==="
  for spec_dir in "$delta_specs_dir"/*/; do
    [ -d "$spec_dir" ] || continue
    capability="$(basename "$spec_dir")"
    spec_file="$spec_dir/spec.md"
    echo "  Capability: $capability"
    if [ -f "${PROJECT_ROOT}/ai/output/specs/$capability/spec.md" ]; then
      echo "    Main spec exists — will merge delta changes"
    else
      echo "    Main spec does not exist — will create from delta (only ADDED is valid here)"
    fi
    if [ -f "$spec_file" ]; then
      # crude section-aware count: requirements are counted under whichever ## delta header precedes them
      awk '
        BEGIN { a=0; m=0; r=0; n=0; sec=""; infence=0 }
        /^```/ { infence=!infence; next }
        infence { next }
        /^## ADDED Requirements/    { sec="A"; next }
        /^## MODIFIED Requirements/ { sec="M"; next }
        /^## REMOVED Requirements/  { sec="R"; next }
        /^## RENAMED Requirements/  { sec="N"; next }
        /^## /                      { sec=""; next }
        /^### Requirement:/ {
          if (sec=="A") a++
          else if (sec=="M") m++
          else if (sec=="R") r++
        }
        /^FROM:/ {
          if (sec=="N") n++
        }
        END { printf "    Operations: +%d added, ~%d modified, -%d removed, →%d renamed\n", a, m, r, n }
      ' "$spec_file"
    fi
  done
else
  echo "No delta specs to sync"
fi

#!/usr/bin/env bash
# Assess delta specs in a change (list capabilities + whether main spec exists).
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
    echo "  Capability: $capability"
    if [ -f "${PROJECT_ROOT}/ai/output/specs/$capability/spec.md" ]; then
      echo "    Main spec exists — will merge delta changes"
    else
      echo "    Main spec does not exist — will create from delta"
    fi
  done
else
  echo "No delta specs to sync"
fi

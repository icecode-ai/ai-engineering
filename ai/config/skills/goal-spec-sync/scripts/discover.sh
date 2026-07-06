#!/usr/bin/env bash
# Discover specs (from a change or ai/output/specs/), modules, and memories.
# Usage: discover.sh [<change-name>]
set -euo pipefail
change_name="${1:-}"

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

echo "=== Available specs ==="
if [ -n "$change_name" ] && [ -f "${PROJECT_ROOT}/ai/output/changes/$change_name/.openspec.yaml" ]; then
  change_specs="${PROJECT_ROOT}/ai/output/changes/$change_name/specs"
  if [ -d "$change_specs" ]; then
    echo "From change '$change_name':"
    for spec_file in "$change_specs"/*/spec.md; do
      [ -f "$spec_file" ] || continue
      echo "  $(basename "$(dirname "$spec_file")")"
    done
  fi
else
  for spec_dir in "${PROJECT_ROOT}/ai/output/specs"/*/; do
    [ -d "$spec_dir" ] || continue
    echo "  $(basename "$spec_dir")"
  done
fi

echo "=== Available modules ==="
for module_dir in "${PROJECT_ROOT}/modules"/*/; do
  [ -d "$module_dir" ] || continue
  echo "  $(basename "$module_dir")"
done

echo "=== Available memories ==="
for memory_file in "${PROJECT_ROOT}/ai/output/memories"/*; do
  [ -f "$memory_file" ] || continue
  echo "  $(basename "$memory_file")"
done

#!/usr/bin/env bash
# Create a spec change directory with .spec.yaml metadata.
# Usage: create-change.sh <change-name>
# Exits 1 if the change already exists and is non-empty.
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: create-change.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
if [ -d "$change_dir" ] && [ "$(ls -A "$change_dir" 2>/dev/null)" ]; then
  echo "EXISTS: Change '$name' already exists."
  echo "Ask user: continue with existing change, or create a new one with a different name."
  exit 1
fi
mkdir -p "$change_dir"
{
  # schema is metadata only — no script reads it; the active schema is set in ai/config/spec-config.yaml.
  echo 'schema: spec-driven'
  echo "created: $(date +%Y-%m-%d)"
} > "$change_dir/.spec.yaml"
echo "Created change directory: $change_dir"

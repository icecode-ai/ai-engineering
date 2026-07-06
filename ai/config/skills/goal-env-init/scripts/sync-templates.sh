#!/usr/bin/env bash
# Sync plugin ai/ templates into project ai/ (mirror; preserve git.tsv & spec-config.yaml).
# Usage: sync-templates.sh <PLUGIN_ROOT>
set -euo pipefail
PLUGIN_ROOT="${1:-}"

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

SRC="${PLUGIN_ROOT}/ai"
DST="${PROJECT_ROOT}/ai"

if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$SRC" ]; then
  echo "PLUGIN_ROOT not set or plugin ai/ missing at '${SRC}' — skip template sync."
  echo "Set PLUGIN_ROOT to the plugin root (parent of commands/) and re-run this step."
  exit 0
fi
if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync not available — skip template sync (install rsync to enable)."
  exit 0
fi

# config/git.tsv and config/spec-config.yaml: copy ONLY if absent (user-owned once present)
for f in config/git.tsv config/spec-config.yaml; do
  if [ -f "$SRC/$f" ] && [ ! -f "$DST/$f" ]; then
    mkdir -p "$(dirname "$DST/$f")"
    cp "$SRC/$f" "$DST/$f"
    echo "copied (new): $f"
  else
    echo "skip (exists or no source): $f"
  fi
done

# Mirror everything else under plugin ai/ into project ai/ (overwrite changed, delete removed)
find "$SRC" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' entry; do
  name="$(basename "$entry")"
  if [ "$name" = "config" ]; then
    rsync -a --delete --exclude='/git.tsv' --exclude='/spec-config.yaml' \
      "$SRC/config/" "$DST/config/"
    echo "mirrored: config/ (git.tsv & spec-config.yaml preserved)"
  else
    rsync -a --delete "$SRC/$name/" "$DST/$name/"
    echo "mirrored: $name/"
  fi
done

echo "Template sync complete."

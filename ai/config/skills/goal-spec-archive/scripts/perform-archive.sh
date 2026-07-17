#!/usr/bin/env bash
# Archive a change directory into ai/output/changes/archive/YYYY-MM-DD-<name>/.
# Usage: perform-archive.sh <change-name>
# Exits 1 (EXISTS:) if the target archive directory already exists.
set -euo pipefail
name="${1:-}"
[ -z "$name" ] && { echo "Usage: perform-archive.sh <change-name>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
archive_dir="${PROJECT_ROOT}/ai/output/changes/archive"
mkdir -p "$archive_dir"
archive_name="$(date +%F)-$name"
if [ -d "$archive_dir/$archive_name" ]; then
  echo "EXISTS: Target archive directory already exists: $archive_dir/$archive_name"
  echo "Options: 1. Rename the existing archive  2. Delete the existing archive if it's a duplicate  3. Wait until a different date to archive"
  exit 1
fi
mv "$change_dir" "$archive_dir/$archive_name"
echo "✓ Change '$name' archived to $archive_dir/$archive_name"

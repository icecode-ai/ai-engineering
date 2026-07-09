#!/usr/bin/env bash
# Scan a repository's uncommitted changes for risk categories.
# Usage: scan-risks.sh <target_repo>
#   <target_repo> — path relative to workspace root: "." or "modules/<name>"
# Output:
#   COUNT:<n>            — number of candidate files (always first line)
#   LARGE:<path>         — file > 10 MB
#   SUSPICIOUS:<path>    — filename matches secret/key patterns
#   ARTIFACT:<path>      — path under unignored build/artifact dirs
# Secret-content judgment is left to the caller (read the flagged file).
set -euo pipefail
repo="${1:-}"
[ -n "$repo" ] || { echo "Usage: scan-risks.sh <target_repo>"; exit 1; }

PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

target="${PROJECT_ROOT}/${repo}"
[ -d "$target" ] || { echo "(not a directory: $repo)" >&2; exit 1; }

cd "$target"

threshold=$((10 * 1024 * 1024))

total=$(git status --porcelain --untracked-files=all | wc -l | tr -d ' ')
echo "COUNT:$total"
if [ "$total" -eq 0 ]; then
  exit 0
fi

while IFS= read -r line; do
  # Strip the 3-character status prefix ("XY ").
  path="${line#???}"
  # Rename: "new -> old" — keep the new path.
  path="${path%% -> *}"
  # Strip surrounding double quotes (porcelain quotes special chars).
  path="${path#\"}"
  path="${path%\"}"
  [ -n "$path" ] || continue
  [ -e "$path" ] || continue

  base="$(basename "$path")"

  # Large file
  if [ "$(uname)" = "Darwin" ]; then
    size=$(stat -f%z "$path" 2>/dev/null || echo 0)
  else
    size=$(stat -c%s "$path" 2>/dev/null || echo 0)
  fi
  size="${size:-0}"
  if [ "$size" -gt "$threshold" ]; then
    printf 'LARGE:%s\n' "$path"
  fi

  # Suspicious filename
  case "$base" in
    *.env|*.pem|*.key|id_rsa|id_ed25519|*.p12|*.pfx|credentials*|secrets*|.npmrc|.pypirc)
      printf 'SUSPICIOUS:%s\n' "$path"
      ;;
  esac

  # Unignored artifact paths
  case "$path" in
    node_modules/*|*/node_modules/*|\
    dist/*|*/dist/*|\
    build/*|*/build/*|\
    out/*|*/out/*|\
    target/*|*/target/*|\
    .next/*|*/.next/*|\
    __pycache__/*|*/__pycache__/*|\
    coverage/*|*/coverage/*|\
    *.log)
      printf 'ARTIFACT:%s\n' "$path"
      ;;
  esac
done < <(git status --porcelain --untracked-files=all)

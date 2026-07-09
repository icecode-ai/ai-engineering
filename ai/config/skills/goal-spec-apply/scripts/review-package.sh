#!/usr/bin/env bash
# Write a review package (per-repo diff vs HEAD) for a list of changed files.
# Module-aware: groups files by their owning git repo (git rev-parse --show-toplevel),
# so changes inside nested module repos (modules/*) are diffed within each module.
# No staging or commits required — tracked files use `git diff HEAD`, untracked (new)
# files are shown in full via `git diff --no-index /dev/null`. Read-only; touches no index.
#
# Usage: review-package.sh <file-list> <out-file>
#   <file-list> — file containing one path per line (relative to workspace root, or absolute)
#   <out-file>  — where to write the review package
# Prints the out-file path on success.
set -euo pipefail
file_list="${1:-}"
out="${2:-}"
[ -n "$file_list" ] && [ -n "$out" ] || { echo "Usage: review-package.sh <file-list> <out-file>"; exit 1; }
[ -f "$file_list" ] || { echo "file-list not found: $file_list"; exit 1; }

# Resolve workspace root (dir containing ai/ and modules/)
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Map each file to its owning repo toplevel + repo-relative path; sort by repo for grouping.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    /*) abs="$f" ;;
    *) abs="$PROJECT_ROOT/$f" ;;
  esac
  [ -e "$abs" ] || continue
  d="$(dirname "$abs")"
  # canonicalize to physical path (e.g. macOS /tmp -> /private/tmp) so the prefix-strip matches git's physical toplevel
  abs="$(cd "$d" && pwd -P)/$(basename "$abs")"
  toplevel="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null)" || continue
  rel="${abs#"$toplevel"/}"
  printf '%s\t%s\n' "$toplevel" "$rel"
done < "$file_list" | sort > "$tmp"

{
  echo "# Review package (working-tree diff vs HEAD, per-repo)"
  echo
  echo "## Files"
  cat "$file_list"
  echo

  prev_repo=""
  while IFS=$'\t' read -r repo rel; do
    [ -z "$repo" ] && continue
    if [ "$repo" != "$prev_repo" ]; then
      echo
      echo "## Repo: $repo"
      prev_repo="$repo"
    fi
    echo
    echo "### $rel"
    if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
      git -C "$repo" diff -U10 HEAD -- "$rel" 2>/dev/null || echo "(diff unavailable for $rel)"
    else
      git -C "$repo" diff --no-index /dev/null "$rel" 2>/dev/null || true
    fi
  done < "$tmp"
} > "$out"
echo "$out"

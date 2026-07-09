#!/usr/bin/env bash
# Detect the mainline branch and print the merge-base of HEAD against it.
# Used by /ai-spec-apply step 8 to scope the final whole-branch review.
# No arguments; run from the workspace root (MAIN repo).
set -euo pipefail

mainline="$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | cut -d/ -f2)" || mainline=""
if [ -z "$mainline" ]; then
  if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    mainline="main"
  elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    mainline="master"
  else
    mainline="main"
  fi
fi
git merge-base HEAD "$mainline"

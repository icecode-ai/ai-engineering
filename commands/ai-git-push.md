---
description: Push git changes across MAIN and modules
argument-hint: [<target>]
---

Push local commits to git remotes. Supports pushing for the main project and modules.

**IMPORTANT**: Never push anything under `readonly-dependencies/` — it is a read-only knowledge base.

**Input**: One optional argument — the target scope. Defaults to `ALL`.

| Target | Scope |
|--------|-------|
| `ALL` (default) | Main project + all modules |
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |

**Steps**

1. **Determine project root and target scope**

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   target="${1:-ALL}"
   ```

2. **If target is `ALL` or `MAIN` — check for incomplete changes before pushing**

   Before pushing the main project, verify there are no incomplete tasks or unarchived changes in `ai/output/changes/`:

   ```bash
   if [ "$target" = "ALL" ] || [ "$target" = "MAIN" ]; then
     changes_dir="${PROJECT_ROOT}/ai/output/changes"
     has_incomplete=false

     # Check each active (non-archived) change for incomplete tasks
     for change in "$changes_dir"/*/; do
       [ -d "$change" ] || continue
       change_name="$(basename "$change")"
       [ "$change_name" = "archive" ] && continue

       tasks_file="${change}tasks.md"
       if [ -f "$tasks_file" ]; then
         total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
         done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
         pending=$((total - done_count))
         if [ "$pending" -gt 0 ]; then
           echo "⚠ Change '$change_name' has $pending incomplete task(s)"
           has_incomplete=true
         fi
       else
         echo "⚠ Change '$change_name' is missing tasks.md"
         has_incomplete=true
       fi

       # Check for missing required artifacts
       for artifact in proposal.md design.md tasks.md; do
         if [ ! -f "${change}${artifact}" ]; then
           echo "⚠ Change '$change_name' is missing $artifact"
           has_incomplete=true
         fi
       done
     done

     # List unarchived changes count
     active_count=$(ls -1d "$changes_dir"/*/ 2>/dev/null | grep -v '/archive/$' | wc -l | tr -d ' ') || active_count=0
     if [ "$active_count" -gt 0 ]; then
       echo "Found $active_count active (unarchived) change(s) in ai/output/changes/"
     fi

     if [ "$has_incomplete" = true ]; then
       echo ""
       echo "❌ Cannot push: there are incomplete tasks or missing artifacts in active changes."
       echo "Please complete the tasks or archive the changes first:"
       echo "  - Run /ai-spec-apply <change-name> to finish pending tasks"
       echo "  - Run /ai-spec-archive <change-name> to archive completed changes"
       exit 1
     fi
   fi
   ```

   If the check passes (all tasks complete, no missing artifacts), proceed to step 3 (stage and commit). If incomplete, **stop and prompt the user** to handle the outstanding changes before pushing.

3. **Stage and commit uncommitted changes (with risk interception)**

   Before pulling, commit any uncommitted work in scope so later merge and push can proceed cleanly. Process each repository in scope — `MAIN`, or every module under `modules/` for `ALL`, or the single named module for `{module}`. **Never touch `readonly-dependencies/`.**

   a. List candidate files (modified, staged, and untracked, excluding gitignored) in the repository: `git status --porcelain --untracked-files=all`.
   b. If there are no candidates, skip this repository.
   c. **Risk interception** — for each candidate, check:
      - Large file: size > 10 MB (`stat -f%z "$f"` on macOS / `stat -c%s "$f"` on Linux).
      - Suspicious filename: matches `*.env`, `*.pem`, `*.key`, `id_rsa`, `id_ed25519`, `*.p12`, `*.pfx`, `credentials*`, `secrets*`, `.npmrc`, `.pypirc`.
      - Secret content: text files containing `PRIVATE KEY`, `BEGIN RSA`, `BEGIN OPENSSH PRIVATE KEY`, `BEGIN PGP PRIVATE KEY`, or obvious high-entropy API keys/tokens (read the file to judge).
      - Unignored artifact paths: `node_modules/`, `dist/`, `build/`, `out/`, `target/`, `.next/`, `__pycache__/`, `coverage/`, `*.log`.
   d. **When a candidate is flagged, pause and ask the user per item**: "include" (add it anyway), "exclude" (skip it and keep it in the working tree), or "abort" (stop the entire push). Do not silently commit flagged files.
   e. After all flagged items are resolved, stage the remaining candidates with `git add -A` (respects `.gitignore`); for any "exclude" item that was staged, unstage it with `git restore --staged <file>`.
   f. Generate a conventional-commit message from the diff and the active change in `ai/output/changes/` (the non-archived change matching this work): `feat(scope): <summary> [ai-change: <change-name>]`. Choose type (`feat`/`fix`/`refactor`/`docs`/`chore`/`test`) and scope from the diff. If multiple unrelated changes are present, split into multiple logical commits. If there is no active change, use `chore: <summary>` without the tag.
   g. Commit with `git commit -m "<message>"`. Do not push yet.

4. **Pull latest content for the target scope**

   ```bash
   if [ "$target" = "MAIN" ] || [ "$target" = "ALL" ]; then
     echo "=== Pull MAIN ==="
     git pull 2>&1 || echo "Pull conflicts in MAIN — will auto-resolve"
   fi

   if [ "$target" = "ALL" ]; then
     for dir in "${PROJECT_ROOT}/modules"/*/; do
       [ -d "$dir/.git" ] || continue
       echo "=== Pull module: $(basename "$dir") ==="
       (cd "$dir" && git pull 2>&1) || echo "Pull conflicts in $(basename "$dir") — will auto-resolve"
     done
   elif [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
     echo "=== Pull module: $target ==="
     (cd "${PROJECT_ROOT}/modules/$target" && git pull 2>&1) || echo "Pull conflicts in $target — will auto-resolve"
   fi
   ```

   Only MAIN and modules are pulled (matching push scope). Dependencies are never pulled here.

5. **Sync mainline into the current branch**

   ```bash
   detect_mainline() {
     local branch
     branch=$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | cut -d/ -f2) || branch=""
     if [ -z "$branch" ]; then
       if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
         branch="main"
       elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
         branch="master"
       else
         branch="main"
       fi
     fi
     echo "$branch"
   }

   if [ "$target" = "MAIN" ] || [ "$target" = "ALL" ]; then
     echo "=== Merge mainline into MAIN ==="
     mainline=$(detect_mainline)
     git merge "$mainline" 2>&1 || echo "Merge conflicts in MAIN — will auto-resolve"
   fi

   if [ "$target" = "ALL" ]; then
     for dir in "${PROJECT_ROOT}/modules"/*/; do
       [ -d "$dir/.git" ] || continue
       echo "=== Merge mainline into module: $(basename "$dir") ==="
       (cd "$dir" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge conflicts in $(basename "$dir") — will auto-resolve"
     done
   elif [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
     echo "=== Merge mainline into module: $target ==="
     (cd "${PROJECT_ROOT}/modules/$target" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge conflicts in $target — will auto-resolve"
   fi
   ```

   Only MAIN and modules are merged. Dependencies are never merged here.

6. **Resolve conflicts automatically**

   If steps 4 or 5 produced merge conflicts, automatically resolve them without prompting the user:

   1. List conflicted files with `git diff --name-only --diff-filter=U` (run inside each repository that conflicted).
   2. For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus the surrounding code and recent commit context to understand both sides' intent.
   3. Edit the file to produce the correct merged result: combine non-overlapping changes from both sides; where they genuinely conflict, choose the semantically correct side based on the code's purpose. Remove all conflict markers.
   4. Stage each resolved file with `git add <file>`.
   5. Finalize the merge with `git commit` (default merge message) if the merge is still in progress.
   6. Do not abort the merge, do not discard changes, do not ask for confirmation — resolve and proceed.

   Repeat for every repository (MAIN and modules) that has conflicts.

7. **Push based on target scope**

   **If target is `ALL`**:

   ```bash
   echo "=== MAIN ==="
   git push 2>&1 || echo "Push failed for MAIN"

   for dir in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$dir/.git" ] || continue
     echo "=== Module: $(basename "$dir") ==="
     (cd "$dir" && git push 2>&1) || echo "Push failed for $(basename "$dir")"
   done
   ```

   **If target is `MAIN`**:

   ```bash
   git push 2>&1 || echo "Push failed for MAIN"
   ```

   **If target is a module name**:

   ```bash
   if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/modules/$target" && git push 2>&1) || echo "Push failed for module $target"
   else
     echo "Module '$target' not found or is not a git repository"
   fi
   ```

   **If target is anything else** (including a dependency name):

   ```bash
   echo "Target '$target' not found, or push does not apply to read-only dependencies"
   ```

**Guardrails**
- Never push anything under `readonly-dependencies/` — it is read-only and excluded from pull/merge/commit/push
- For `ALL` or `MAIN` targets, always check `ai/output/changes/` for incomplete tasks or unarchived changes before pushing (fail-fast)
- Before pushing: stage+commit uncommitted work with risk interception (step 3), pull latest (step 4), merge mainline into the current branch (step 5), and auto-resolve any conflicts (step 6)
- Risk interception (step 3) pauses to ask the user per flagged file (include/exclude/abort); never silently commit secrets, large files, or unignored artifacts
- Only committed changes are pushed — step 3 ensures uncommitted work (including AI-created files) is committed first
- If push fails due to remote divergence, inform the user and suggest re-running `/ai-git-push` (which now pulls and merges first)

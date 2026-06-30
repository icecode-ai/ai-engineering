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

   Before pushing the main project, verify there are no incomplete tasks or unarchived changes in `ai/changes/`:

   ```bash
   if [ "$target" = "ALL" ] || [ "$target" = "MAIN" ]; then
     changes_dir="${PROJECT_ROOT}/ai/changes"
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
       echo "Found $active_count active (unarchived) change(s) in ai/changes/"
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

   If the check passes (all tasks complete, no missing artifacts), proceed to push. If incomplete, **stop and prompt the user** to handle the outstanding changes before pushing.

3. **Push based on target scope**

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
- Never push anything under `readonly-dependencies/` — it is read-only and excluded from push
- For `ALL` or `MAIN` targets, always check `ai/changes/` for incomplete tasks or unarchived changes before pushing
- Remind the user that only committed changes are pushed; uncommitted changes won't be included
- If push fails due to remote divergence, inform the user and suggest pulling first

---
description: Archive a completed change
argument-hint: [<change-name>]
---

Archive a completed change. Moves the change directory into the archive to keep the active changes list clean.

**Input**: Optionally specify a change name after `/ai-spec-archive` (e.g., `/ai-spec-archive add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   List available active changes:

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   echo "Active changes:"
   ls -1 "${PROJECT_ROOT}/ai/changes/" 2>/dev/null | grep -v '^archive$' || echo "  (no active changes)"
   ```

   Use the **AskUserQuestion tool** to let the user select.

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check artifact completion status**

   ```bash
   # $name = selected change (chosen by user in step 1)
   change_dir="${PROJECT_ROOT}/ai/changes/$name"
   if [ ! -d "$change_dir" ]; then
     echo "Change '$name' not found."
     exit 1
   fi

   incomplete=false
   for artifact in proposal.md design.md tasks.md; do
     if [ ! -f "$change_dir/$artifact" ]; then
       echo "⚠ $artifact (incomplete)"
       incomplete=true
     fi
   done

   if [ "$incomplete" = true ]; then
     echo "Some artifacts are incomplete. Archive anyway?"
     # Prompt user for confirmation
   fi
   ```

3. **Check task completion status**

   ```bash
   tasks_file="$change_dir/tasks.md"
   if [ -f "$tasks_file" ]; then
     total=$(grep -cE '^\s*[-*]\s+\[[ x]\]' "$tasks_file" 2>/dev/null) || total=0
     done_count=$(grep -cE '^\s*[-*]\s+\[[x]\]' "$tasks_file" 2>/dev/null) || done_count=0
     pending=$((total - done_count))

     if [ "$pending" -gt 0 ]; then
       echo "⚠ $pending tasks still incomplete. Archive anyway?"
       # Prompt user for confirmation
     fi
   fi
   ```

   **If incomplete tasks found**: Display warning and prompt for confirmation. Proceed if user confirms.

4. **Sync delta specs to main specs (if delta specs exist)**

   Before archiving, check if the change has delta specs that need to be synced to the main specs directory. Delta specs contain ADDED/MODIFIED/REMOVED/RENAMED requirement sections that need to be merged into the corresponding main spec files.

   ```bash
   delta_specs_dir="$change_dir/specs"
   if [ -d "$delta_specs_dir" ] && [ "$(ls -A "$delta_specs_dir" 2>/dev/null)" ]; then
     echo "=== Delta specs found ==="
     for spec_dir in "$delta_specs_dir"/*/; do
       [ -d "$spec_dir" ] || continue
       capability="$(basename "$spec_dir")"
       echo "  Capability: $capability"
       if [ -f "${PROJECT_ROOT}/ai/specs/$capability/spec.md" ]; then
         echo "    Main spec exists — will merge delta changes"
       else
         echo "    Main spec does not exist — will create from delta"
       fi
     done
   else
     echo "No delta specs to sync"
   fi
   ```

   **If delta specs exist**, for each delta spec:
   1. Read the delta spec file (`$change_dir/specs/<capability>/spec.md`)
   2. Parse the delta sections: `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements`
   3. Read the corresponding main spec (`ai/specs/<capability>/spec.md`) if it exists
   4. Apply the delta operations in order: RENAMED → REMOVED → MODIFIED → ADDED
   5. Write the updated main spec to `ai/specs/<capability>/spec.md`

   **Ask the user** whether to sync before archiving. Options: "Sync now (recommended)", "Archive without syncing". Proceed to archive regardless of choice.

5. **Perform the archive**

   ```bash
   archive_dir="${PROJECT_ROOT}/ai/changes/archive"
   mkdir -p "$archive_dir"

   archive_name="$(date +%F)-$name"

   if [ -d "$archive_dir/$archive_name" ]; then
     echo "Target archive directory already exists: $archive_dir/$archive_name"
     echo "Options:"
     echo "1. Rename the existing archive"
     echo "2. Delete the existing archive if it's a duplicate"
     echo "3. Wait until a different date to archive"
     # Prompt user for resolution
   else
     mv "$change_dir" "$archive_dir/$archive_name"
     echo "✓ Change '$name' archived to $archive_dir/$archive_name"
   fi
   ```

6. **Display summary**

   ```
   ## Archive Complete

   **Change:** <change-name>
   **Archived to:** ai/changes/archive/YYYY-MM-DD-<name>/
   **Specs:** ✓ Synced to main specs (or "No delta specs" / "Sync skipped")
   ```

   If there were warnings:

   ```
   ## Archive Complete (with warnings)

   **Change:** <change-name>
   **Archived to:** ai/changes/archive/YYYY-MM-DD-<name>/
   **Specs:** Synced / Sync skipped / No delta specs

   **Warnings:**
   - Archived with incomplete artifacts
   - Archived with N incomplete tasks
   - Delta spec sync was skipped (user chose to skip)

   Review the archive if this was not intentional.
   ```

**Guardrails**
- Always prompt for change selection if not provided
- Don't block archive on warnings — just inform and confirm
- Preserve `.openspec.yaml` when archiving (it moves with the directory)
- Show clear summary of what happened
- If delta specs exist, always run the sync assessment and show the summary before prompting

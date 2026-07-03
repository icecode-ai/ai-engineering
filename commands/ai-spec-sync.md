---
description: Sync specs and memories from the main project to related modules
argument-hint: [<change-name>]
---

Sync specification and memory content from the main project's `ai/` directory to the corresponding locations in each module.

**Input**: Optional change name. If provided, only sync specs related to that change. If omitted, sync all specs.

**Steps**

1. **Discover specs and modules, then sync specs to modules**

   For each spec file in `ai/output/specs/` (or from a change), determine which module it relates to and sync it to `modules/<module>/ai/output/specs/<capability>/`:

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   change_name="${1:-}"

   # Discover available specs (from a change, or from ai/output/specs/)
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

   # Discover available modules
   echo "=== Available modules ==="
   for module_dir in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$module_dir" ] || continue
     echo "  $(basename "$module_dir")"
   done
   ```

   For each spec, read its content to determine which module(s) it relates to, then read the existing target files to decide merge vs. replace vs. skip. Perform a targeted copy for each confirmed mapping:

   ```bash
   # $capability = spec name; $module = target module (both determined by AI)
   target="${PROJECT_ROOT}/modules/$module/ai/output/specs/$capability"
   mkdir -p "$target"
   cp -r "${PROJECT_ROOT}/ai/output/specs/$capability/." "$target/" 2>/dev/null || true
   echo "Synced spec '$capability' to module '$module'"
   ```

2. **Sync memories to modules**

   For each memory file in `ai/output/memories/`, determine which module it relates to and sync it:

   ```bash
   # Discover available memories ($PROJECT_ROOT from step 1)
   echo "=== Available memories ==="
   for memory_file in "${PROJECT_ROOT}/ai/output/memories"/*; do
     [ -f "$memory_file" ] || continue
     echo "  $(basename "$memory_file")"
   done
   ```

   For each memory, read its content to determine which module(s) it relates to, then read the existing target files to decide merge vs. replace vs. skip. Perform a targeted copy for each confirmed mapping:

   ```bash
   # $memory_name and $module determined by AI
   target="${PROJECT_ROOT}/modules/$module/ai/output/memories"
   mkdir -p "$target"
   cp "${PROJECT_ROOT}/ai/output/memories/$memory_name" "$target/" 2>/dev/null || true
   echo "Synced memory '$memory_name' to module '$module'"
   ```

3. **Verify sync results**

   ```bash
   echo "=== Sync Complete ==="
   echo "Specs synced to module ai/output/specs/ directories"
   echo "Memories synced to module ai/output/memories/ directories"
   ```

**Guardrails**
- Only sync content that is relevant to each module — AI should determine if content belongs in an existing file (update) or as a new file
- Do NOT overwrite existing module-specific content without confirmation
- Read the existing files in the target module directory before syncing to decide merge vs replace vs skip

---
description: Initialize or update project environment for AI-assisted development
---

Initialize or update the project environment. Sets up the standard directory structure (`ai/`, `modules/`, `readonly-dependencies/`) and generates guidance files for the main project and each module.

**Guidance file generation methodology**

Target file & environment:
- **Claude Code** → `CLAUDE.md`. Run the `/init` skill; afterward re-merge any user-specific sections it may have overwritten.
- **Other agents** → `AGENTS.md`. Generate via the approach below.

How to investigate:
- Read `README*`, root manifests, workspace config, lockfiles; build/test/lint/formatter/typecheck/codegen config; CI workflows; existing instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`); `opencode.json`.
- Prefer executable sources of truth over prose; if docs conflict with config/scripts, trust the executable source.
- If architecture is still unclear, inspect a few representative code files for real entrypoints and package boundaries.

What to extract (high-signal, repo-specific only):
- exact developer commands, especially non-obvious ones; how to run a single test/package/focused verification
- required command order when it matters (e.g. `lint -> typecheck -> test`)
- monorepo/multi-package boundaries, major directory ownership, real app/library entrypoints
- framework/toolchain quirks: generated code, migrations, codegen, build artifacts, env loading, dev servers, deploy flow
- repo-specific style/workflow conventions differing from defaults; testing quirks (fixtures, integration prerequisites, snapshots, services, flaky suites)
- constraints from existing instruction files worth preserving

Create vs. update:
- **Target missing** — Claude Code: run `/init` (fallback: the approach above). Other agents: use the approach above.
- **Other-environment file exists instead** (e.g. targeting `CLAUDE.md` but only `AGENTS.md` present) — treat it as the primary fact source, re-verify against current sources, generate the target from it, and leave the other file in place. Keep both files in sync when facts change.
- **Target exists** — re-extract current facts and compare. If only wording/formatting/unchanged facts differ, leave as-is. If substantive differences exist (new/changed commands, architecture, added/removed modules or dependencies): Claude Code runs `/init` then re-merges user-specific sections; other agents update in place.

Preserve user-specific content: keep the user's special references/sections (e.g. development specs, custom conventions); update only the factual, project-derived portions.
Writing rules: short sections and bullets; include only what an agent would otherwise miss. Exclude generic advice, tutorials, obvious conventions, speculation. When in doubt, omit.

**Steps**

1. **Discover project root, create standard directories, and configure .gitignore**

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   DIRS=(
     "ai"
     "ai/archetypes"
     "ai/changes"
     "ai/changes/archive"
     "ai/memories"
     "ai/specs"
     "modules"
     "readonly-dependencies"
   )
   for dir in "${DIRS[@]}"; do
     target="${PROJECT_ROOT}/${dir}"
     if [ ! -d "$target" ]; then
       mkdir -p "$target"
       echo "Created: ${dir}/"
     else
       echo "Exists: ${dir}/"
     fi
   done

   gitignore_file="${PROJECT_ROOT}/.gitignore"
   entry="readonly-dependencies/"
   if [ ! -f "$gitignore_file" ]; then
     printf '%s\n' "$entry" > "$gitignore_file"
     echo "Created .gitignore with readonly-dependencies entry"
   elif ! grep -qF "$entry" "$gitignore_file"; then
     printf '%s\n' "$entry" >> "$gitignore_file"
     echo "Added '${entry}' to .gitignore"
   else
     echo "'${entry}' already in .gitignore"
   fi

   config_file="${PROJECT_ROOT}/ai/config.yaml"
   if [ ! -f "$config_file" ]; then
     {
       echo 'schema: spec-driven'
       echo ''
       echo '# Project context (optional)'
       echo '# This is shown to AI when creating artifacts.'
       echo '# Add your tech stack, conventions, style guides, domain knowledge, etc.'
       echo '# Example:'
       echo '#   context: |'
       echo '#     Tech stack: TypeScript, React, Node.js'
       echo '#     We use conventional commits'
       echo '#     Domain: e-commerce platform'
       echo ''
       echo '# Per-artifact rules (optional)'
       echo '# Add custom rules for specific artifacts.'
       echo '# Example:'
       echo '#   rules:'
       echo '#     proposal:'
       echo '#       - Keep proposals under 500 words'
       echo '#       - Always include a "Non-goals" section'
       echo '#     tasks:'
       echo '#       - Break tasks into chunks of max 2 hours'
     } > "$config_file"
     echo "Created: ai/config.yaml"
   else
     echo "Exists: ai/config.yaml"
   fi
   echo "Environment initialized at: ${PROJECT_ROOT}"
   ```

2. **Generate guidance file for each module**

   For each directory under `modules/`, generate or update its guidance file (`modules/$module/CLAUDE.md` for Claude Code, `modules/$module/AGENTS.md` for other agents) following the **Guidance file generation methodology** above. Module guidance files do NOT carry the `readonly-dependencies/` marking.

   ```bash
   for module in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$module" ] || continue
     echo "Processing module: $(basename "$module")"
   done
   ```

3. **Generate main project guidance file**

   First check whether there is any substantial content to summarize. Recursively scan `modules/` and `readonly-dependencies/` for regular files (excluding the guidance files `AGENTS.md`/`CLAUDE.md` themselves, since step 2 may have generated them):

   ```bash
   has_substantial_files() {
     local dir="$1"
     [ -d "$dir" ] || return 1
     find "$dir" -type f ! -name AGENTS.md ! -name CLAUDE.md -print -quit | grep -q .
   }

   if ! has_substantial_files "${PROJECT_ROOT}/modules" && ! has_substantial_files "${PROJECT_ROOT}/readonly-dependencies"; then
     echo "Both modules/ and readonly-dependencies/ are empty (or only contain empty subdirectories); skipping main project guidance file generation."
   else
     echo "Generating main project guidance file..."
   fi
   ```

   If the check passes (substantial content exists), generate or update the main project guidance file at the project root following the **Guidance file generation methodology** above, reading the project's README, configs, and all module guidance files as inputs. Additionally:
   - **Required marking**: explicitly state `readonly-dependencies/` is a READ-ONLY knowledge base — never write, modify, or delete.

**Guardrails**
- `readonly-dependencies/` is a read-only knowledge base — never write, modify, or delete files inside it
- Do NOT add `modules/` to `.gitignore` (but `readonly-dependencies/` should be added)
- For Claude Code, use `CLAUDE.md` as guidance file; for other agents, use `AGENTS.md`

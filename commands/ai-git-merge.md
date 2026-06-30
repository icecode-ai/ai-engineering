---
description: Merge mainline branch into current branch across MAIN, modules, and dependencies
argument-hint: [<target>]
---

Merge the mainline branch into the current branch across git repositories.

**Input**: One optional argument — the target scope. Defaults to `ALL`.

| Target | Scope |
|--------|-------|
| `ALL` (default) | Main project + all modules + all dependencies |
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |
| `{dependency-name}` | A specific dependency in `readonly-dependencies/` |

**Steps**

1. **Merge based on target scope**

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   target="${1:-ALL}"

   # Detect the mainline branch of the current repository (run inside the repo dir)
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
   ```

   **If target is `ALL`**:

   ```bash
   echo "=== MAIN ==="
   mainline=$(detect_mainline)
   git merge "$mainline" 2>&1 || echo "Merge failed or conflict in MAIN, conflicts detected — will auto-resolve"

   for dir in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$dir/.git" ] || continue
     echo "=== Module: $(basename "$dir") ==="
     (cd "$dir" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge failed or conflict in $(basename "$dir"), conflicts detected — will auto-resolve"
   done

   for dir in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
     [ -d "$dir/.git" ] || continue
     echo "=== Dependency: $(basename "$dir") ==="
     (cd "$dir" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge failed or conflict in $(basename "$dir"), conflicts detected — will auto-resolve"
   done
   ```

   **If target is `MAIN`**:

   ```bash
   mainline=$(detect_mainline)
   git merge "$mainline" 2>&1 || echo "Merge failed or conflict in MAIN, conflicts detected — will auto-resolve"
   ```

   **If target is a module name**:

   ```bash
   if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/modules/$target" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge failed or conflict in module $target, conflicts detected — will auto-resolve"
   else
     echo "Module '$target' not found or is not a git repository"
   fi
   ```

   **If target is a dependency name**:

   ```bash
   if [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/readonly-dependencies/$target" && mainline=$(detect_mainline) && git merge "$mainline" 2>&1) || echo "Merge failed or conflict in dependency $target, conflicts detected — will auto-resolve"
   else
     echo "Dependency '$target' not found or is not a git repository"
   fi
   ```

2. **Resolve conflicts automatically**

   If `git merge` produced merge conflicts, automatically resolve them without prompting the user:

   1. List conflicted files with `git diff --name-only --diff-filter=U` (run inside each repository that conflicted).
   2. For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus the surrounding code and recent commit context to understand both sides' intent.
   3. Edit the file to produce the correct merged result: combine non-overlapping changes from both sides; where they genuinely conflict, choose the semantically correct side based on the code's purpose. Remove all conflict markers.
   4. Stage each resolved file with `git add <file>`.
   5. Finalize the merge with `git commit` (default merge message) if the merge is still in progress.
   6. Do not abort the merge, do not discard changes, do not ask for confirmation — resolve and proceed.

   Repeat for every repository (MAIN, modules, and dependencies) that has conflicts.

3. **Generate guidance files for affected modules**

   For each module affected by this merge (i.e. when target is `ALL` or a specific module name), generate or update its guidance file at `modules/$module/`. Skip dependencies — they are read-only and carry no guidance file.

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
   Module guidance files do NOT carry the `readonly-dependencies/` marking.
   Writing rules: short sections and bullets; include only what an agent would otherwise miss. Exclude generic advice, tutorials, obvious conventions, speculation. When in doubt, omit.

4. **Generate main project guidance file (all targets)**

   For all targets (`ALL`, `MAIN`, module, and dependency), generate or update the main project guidance file at the project root. Follow the same methodology as step 3 above (Target file & environment, How to investigate, What to extract, Create vs. update, Preserve user-specific content, Writing rules).

   Additionally:
   - **Required marking**: explicitly state `readonly-dependencies/` is a READ-ONLY knowledge base — never write, modify, or delete.

**Guardrails**
- Validate the mainline branch exists before attempting merge (detected dynamically per repo)
- For dependencies, merge only syncs the dependency's own `main` into its current branch — do not edit the knowledge content inside `readonly-dependencies/`

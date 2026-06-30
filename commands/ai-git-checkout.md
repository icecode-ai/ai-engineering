---
description: Checkout a git branch across MAIN, modules, and dependencies
argument-hint: <target> <branch>
---

Checkout a git branch across the project. Supports switching branches on the main project, modules, and dependencies.

**Input**: Two required arguments — the target scope and the branch name.

| Target | Scope |
|--------|-------|
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |
| `{dependency-name}` | A specific dependency in `readonly-dependencies/` |

**Steps**

1. **Checkout branch based on target scope**

   Extract arguments and determine target scope:

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   target="${1:-}"
   branch="${2:-}"
   if [ -z "$target" ] || [ -z "$branch" ]; then
     echo "Usage: /ai-git-checkout <target> <branch>"
     exit 1
   fi
   ```

   **If target is `MAIN`** — checkout on main project only:

   ```bash
   git checkout "$branch" 2>&1 || echo "Checkout failed or conflict in MAIN, will auto-resolve via stash"
   ```

   **If target is a module name** — checkout on that specific module:

   ```bash
   if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/modules/$target" && git checkout "$branch" 2>&1) || echo "Checkout failed or conflict in module $target, will auto-resolve via stash"
   else
     echo "Module '$target' not found or is not a git repository"
   fi
   ```

   **If target is a dependency name** — checkout on that specific dependency:

   ```bash
   if [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/readonly-dependencies/$target" && git checkout "$branch" 2>&1) || echo "Checkout failed or conflict in dependency $target, will auto-resolve via stash"
   else
     echo "Dependency '$target' not found or is not a git repository"
   fi
   ```

2. **Resolve checkout conflicts automatically**

   If `git checkout` reported that local uncommitted changes would be overwritten (the checkout did not complete), automatically recover without discarding local changes and without asking the user:

   1. Identify the target repository that failed (MAIN, the module, or the dependency).
   2. Save local changes (including untracked) in that repository with `git stash push -u -m "ai-git-checkout-autostash"`.
   3. Retry `git checkout "$branch"` in the same repository.
   4. Restore the stashed changes with `git stash pop`.
   5. If `git stash pop` produces merge conflicts, resolve them automatically:
      - List conflicted files with `git diff --name-only --diff-filter=U`.
      - For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus surrounding code to understand both sides' intent.
      - Edit to produce the correct merged result: combine non-overlapping changes; where they genuinely conflict, choose the semantically correct side. Remove all conflict markers.
      - Stage each resolved file with `git add <file>`. No commit is needed — the resolved content stays in the working tree.
   6. Do not discard local changes, do not abort, do not ask for confirmation.

   If checkout failed for a reason other than local-change conflicts (e.g., the branch does not exist), report it and stop.

3. **Generate guidance file for the target module (module targets only)**

   If the target is a **module**, generate or update its guidance file at `modules/$target/`. Skip this step for `MAIN` and dependency targets — module guidance files are only for modules.

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

   For all targets (`MAIN`, module, and dependency), generate or update the main project guidance file at the project root. Follow the same methodology as step 3 above (Target file & environment, How to investigate, What to extract, Create vs. update, Preserve user-specific content, Writing rules).

   Additionally:
   - **Required marking**: explicitly state `readonly-dependencies/` is a READ-ONLY knowledge base — never write, modify, or delete.

**Guardrails**
- If checkout fails due to local-change conflicts, auto-recover via stash (step 2) without discarding changes
- Validate the branch exists on the target repository before switching

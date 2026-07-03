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

   Detect the target guidance file at the project root (`CLAUDE.md` for Claude Code, `AGENTS.md` for other agents). Generate or update it using the **fixed workspace-index template** below — the main project is a multi-project workspace, not a buildable project, so do NOT use free-form extraction or the `/init` skill here.

   **Template** — keep all fixed sections verbatim; fill only the scanned tables:

   ```markdown
   # <ProjectName>

   This is a multi-project workspace, **not** a buildable project. There is no build / test / lint / typecheck / task runner at the root.

   ## Directory Structure

   | Path | Description |
   |------|-------------|
   | `ai/config/rules/` | Rules collection |
   | `ai/output/memories/` | Memory artifacts |
   | `ai/output/specs/` | Project spec artifacts |
   | `modules/` | Independent projects collection |
   | `readonly-dependencies/` | Read-only knowledge base |

   ## modules

   Each project under `modules/` is an independent git repository with its own git remote, toolchain, and `guidance file`.

   | Module Name | Path | Guidance File | Description |
   |-------------|------|---------------|-------------|
   | <module> | `modules/<module>` | `modules/<module>/<AGENTS or CLAUDE>.md` | <description> |

   ## readonly-dependencies

   Stores **read-only references** to private dependencies for local reading. Not part of the build; depended on by modules.

   | Dependency Name | Path | Description |
   |-----------------|------|-------------|
   | <dependency> | `readonly-dependencies/<dependency>` | <description> |

   ## rules

   Rules

   | Rule | Path | Description |
   |----------|------|-------------|
   | <rule> | `ai/config/rules/<rule_file>` | <description> |

   ## Workflow

   When working under `modules/`, read the standards in the following order:

   1. The module's guidance file (`AGENTS.md`, or `CLAUDE.md` for Claude Code) at the module root
   2. Rules under `ai/config/rules/` relevant to the module's tech stack, if any

   In case of conflict, the module guidance file takes precedence.

   ## Guardrails

   - `readonly-dependencies/` is a read-only knowledge base: writing / modifying / git pushing / deleting files within it is prohibited.
   ```

   **Scan entries** (run this; output drives the tables):

   ```bash
   echo "PROJECT:$(basename "$PROJECT_ROOT")"
   for d in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$d" ] || continue
     gf="AGENTS.md"; [ -f "${d}CLAUDE.md" ] && gf="CLAUDE.md"
     echo "M:$(basename "$d")|modules/$(basename "$d")|modules/$(basename "$d")/$gf"
   done
   for d in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
     [ -d "$d" ] || continue
     echo "D:$(basename "$d")|readonly-dependencies/$(basename "$d")"
   done
   for f in "${PROJECT_ROOT}/ai/config/rules"/*; do
     [ -f "$f" ] || continue
     echo "R:$(basename "$f")|ai/config/rules/$(basename "$f")"
   done
   ```

   **Description** (one line, ≤100 chars, format: `<purpose/domain> — <key tech stack>`):
   - Read each entry's `README.md` (modules & dependencies) or content (rules)
   - Prioritize business domain + key frameworks/languages; omit fluff
   - Examples: `E-commerce backend — Go/Gin/PostgreSQL` · `Coding standards — naming/formatting/structure`
   - No info available → directory name / filename
   - Empty table → header row only (keep the section)

   **Incremental update**:
   - If the target file already exists, regenerate from the template and compare. If differences are only wording/formatting/unchanged facts, leave as-is. Update ONLY on substantive changes (added/removed/renamed modules, dependencies, or rules).
   - If the other-environment guidance file exists instead (e.g. targeting `CLAUDE.md` but only `AGENTS.md` present), use it as a reference, generate the target from the template, and leave the other file in place. Keep both in sync.
   - Preserve any user-specific content outside the fixed template (e.g. custom development specs the user appended) — update only the template-derived portions.

**Guardrails**
- If checkout fails due to local-change conflicts, auto-recover via stash (step 2) without discarding changes
- Validate the branch exists on the target repository before switching

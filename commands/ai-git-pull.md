---
description: Pull latest git content across MAIN, modules, and dependencies
argument-hint: [<target>]
---

Pull the latest content from git remotes. Supports pulling for the main project, modules, and dependencies.

**Input**: One optional argument — the target scope. Defaults to `ALL`.

| Target | Scope |
|--------|-------|
| `ALL` (default) | Main project + all modules + all dependencies |
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |
| `{dependency-name}` | A specific dependency in `readonly-dependencies/` |

**Steps**

1. **Pull based on target scope**

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

   **If target is `ALL`**:

   ```bash
   echo "=== MAIN ==="
   git pull 2>&1 || echo "Pull failed for MAIN, conflicts detected — will auto-resolve"

   for dir in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$dir/.git" ] || continue
     echo "=== Module: $(basename "$dir") ==="
     (cd "$dir" && git pull 2>&1) || echo "Pull failed for $(basename "$dir"), conflicts detected — will auto-resolve"
   done

   for dir in "${PROJECT_ROOT}/readonly-dependencies"/*/; do
     [ -d "$dir/.git" ] || continue
     echo "=== Dependency: $(basename "$dir") ==="
     (cd "$dir" && git pull 2>&1) || echo "Pull failed for $(basename "$dir"), conflicts detected — will auto-resolve"
   done
   ```

   **If target is `MAIN`**:

   ```bash
   git pull 2>&1 || echo "Pull failed for MAIN, conflicts detected — will auto-resolve"
   ```

   **If target is a module name**:

   ```bash
   if [ -d "${PROJECT_ROOT}/modules/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/modules/$target" && git pull 2>&1) || echo "Pull failed for module $target, conflicts detected — will auto-resolve"
   else
     echo "Module '$target' not found or is not a git repository"
   fi
   ```

   **If target is a dependency name**:

   ```bash
   if [ -d "${PROJECT_ROOT}/readonly-dependencies/$target/.git" ]; then
     (cd "${PROJECT_ROOT}/readonly-dependencies/$target" && git pull 2>&1) || echo "Pull failed for dependency $target, conflicts detected — will auto-resolve"
   else
     echo "Dependency '$target' not found or is not a git repository"
   fi
   ```

2. **Resolve conflicts automatically**

   If `git pull` produced merge conflicts, automatically resolve them without prompting the user:

   1. List conflicted files with `git diff --name-only --diff-filter=U` (run inside each repository that conflicted).
   2. For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus the surrounding code and recent commit context to understand both sides' intent.
   3. Edit the file to produce the correct merged result: combine non-overlapping changes from both sides; where they genuinely conflict, choose the semantically correct side based on the code's purpose. Remove all conflict markers.
   4. Stage each resolved file with `git add <file>`.
   5. Finalize the merge with `git commit` (default merge message) if the merge is still in progress.
   6. Do not abort the merge, do not discard changes, do not ask for confirmation — resolve and proceed.

   Repeat for every repository (MAIN, modules, and dependencies) that has conflicts.

3. **Generate guidance files for affected modules**

   For each module affected by this pull (i.e. when target is `ALL` or a specific module name), generate or update its guidance file at `modules/$module/`. Skip dependencies — they are read-only and carry no guidance file.

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
   | `ai/specs/` | Project spec artifacts |
   | `ai/baselines/` | Baseline standards collection |
   | `ai/memories/` | Memory artifacts |
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

   ## baselines

   Baseline standards

   | Standard | Path | Description |
   |----------|------|-------------|
   | <standard> | `ai/baselines/<standard_file>` | <description> |

   ## Workflow

   When working under `modules/`, read the standards in the following order:

   1. Module guidance file: `modules/<name>/AGENTS.md`
   2. Standards under `ai/baselines/` relevant to the module's tech stack, if any

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
   for f in "${PROJECT_ROOT}/ai/baselines"/*; do
     [ -f "$f" ] || continue
     echo "B:$(basename "$f")|ai/baselines/$(basename "$f")"
   done
   ```

   **Description** (one line, ≤100 chars, format: `<purpose/domain> — <key tech stack>`):
   - Read each entry's `README.md` (modules & dependencies) or content (baselines)
   - Prioritize business domain + key frameworks/languages; omit fluff
   - Examples: `E-commerce backend — Go/Gin/PostgreSQL` · `Coding standards — naming/formatting/structure`
   - No info available → directory name / filename
   - Empty table → header row only (keep the section)

   **Incremental update**:
   - If the target file already exists, regenerate from the template and compare. If differences are only wording/formatting/unchanged facts, leave as-is. Update ONLY on substantive changes (added/removed/renamed modules, dependencies, or baselines).
   - If the other-environment guidance file exists instead (e.g. targeting `CLAUDE.md` but only `AGENTS.md` present), use it as a reference, generate the target from the template, and leave the other file in place. Keep both in sync.
   - Preserve any user-specific content outside the fixed template (e.g. custom development specs the user appended) — update only the template-derived portions.

**Guardrails**
- Skip repositories without a configured remote/upstream and inform the user

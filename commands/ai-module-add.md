---
description: Add a new module from a git repository
argument-hint: <git-url> [<branch-name>]
---

Add a new module to the project by cloning a git repository into the `modules/` directory.

**Input**: Up to two arguments — the git repository URL (required), and an optional branch name (defaults to the default branch).

**Steps**

1. **Clone the repository into modules/**

   Derive the module directory name from the repository name. If the second argument is provided, use it as the branch to clone.

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   url="${1:-}"
   branch="${2:-}"
   [ -z "$url" ] && { echo "Usage: /ai-module-add <git-url> [<branch-name>]"; exit 1; }
   module_name="$(basename "$url" .git)"
   module_dir="${PROJECT_ROOT}/modules/$module_name"
   # An empty directory is treated as non-existent
   if [ -d "$module_dir" ] && [ -n "$(ls -A "$module_dir" 2>/dev/null)" ]; then
     echo "EXISTS: Module '$module_name' already exists and is non-empty."
     echo "ACTION_REQUIRED: Ask the user whether to delete and re-add."
     echo "If confirmed, run: rm -rf \"$module_dir\" then re-run clone."
     echo "If declined, abort."
     exit 1
   fi
   if [ -n "$branch" ]; then
     git clone --branch "$branch" "$url" "$module_dir"
   else
     git clone "$url" "$module_dir"
   fi
   ```

2. **Generate guidance file for the new module**

   Generate or update the guidance file at `modules/$module_name/` (`CLAUDE.md` for Claude Code, `AGENTS.md` for other agents).

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

3. **Re-generate the main project guidance file**

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

   1. The module's guidance file (`AGENTS.md`, or `CLAUDE.md` for Claude Code) at the module root
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
- Validate the git URL is accessible before cloning
- If the module directory already exists, ask the user before overwriting

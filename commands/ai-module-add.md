---
description: Add a new module from a git repository
argument-hint: <git-url> [<branch-name>]
---

Add a new module to the project by cloning a git repository into the `modules/` directory.

**Input**: Up to two arguments — the git repository URL (required), and an optional branch name (defaults to the default branch).

User-provided arguments: `$ARGUMENTS` (first value is the git URL; second value, if present, is the branch — otherwise the default branch is used)

**Steps**

1. **Resolve missing arguments**

   Check `User-provided arguments` above. **If `$ARGUMENTS` is empty (no argument passed)**, use the **AskUserQuestion tool** (open-ended, no preset options) to ask the user for the git repository URL. Do not proceed until a valid URL is provided. **If `$ARGUMENTS` is non-empty**, take the first value as the git URL, skip the prompt, and proceed directly to step 2.

   The `<branch-name>` argument is optional — do not prompt for it; if absent, the default branch is used.

2. **Clone the repository into modules/**

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

   # register in ai/config/git.tsv (path<TAB>url<TAB>branch)
   branch="$(git -C "$module_dir" rev-parse --abbrev-ref HEAD)"
   git_tsv="${PROJECT_ROOT}/ai/config/git.tsv"
   [ -f "$git_tsv" ] || printf '# path\turl\tbranch\n' > "$git_tsv"
   if awk -F'\t' -v p="modules/$module_name" '$1==p {found=1} END{exit !found}' "$git_tsv"; then
     echo "Already registered in ai/config/git.tsv"
   else
     printf '%s\t%s\t%s\n' "modules/$module_name" "$url" "$branch" >> "$git_tsv"
     echo "Registered modules/$module_name in ai/config/git.tsv"
   fi
   ```

3. **Generate guidance file for the new module**

   **Precondition**: the clone succeeded. If cloning failed (URL invalid/inaccessible) or the user declined to overwrite an existing module, **STOP** — do not generate any guidance file.

   Generate or update the guidance files at `modules/$module_name/` — keep `AGENTS.md` and `CLAUDE.md` in sync per the dual-write policy below.

   Dual-write policy: every module keeps BOTH `CLAUDE.md` and `AGENTS.md` in sync. Decide per module:
   - **Both missing** → investigate (approach below) and generate BOTH `CLAUDE.md` and `AGENTS.md` with identical content.
   - **`CLAUDE.md` exists, `AGENTS.md` missing** → copy `CLAUDE.md` to `AGENTS.md`.
   - **`AGENTS.md` exists, `CLAUDE.md` missing** → copy `AGENTS.md` to `CLAUDE.md`.
   - **Both exist** → skip; do not regenerate.

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

   Preserve user-specific content: keep the user's special references/sections (e.g. development specs, custom conventions); update only the factual, project-derived portions.
   Writing rules: short sections and bullets; include only what an agent would otherwise miss. Exclude generic advice, tutorials, obvious conventions, speculation. When in doubt, omit.

4. **Re-generate the main project guidance file**

   Synchronously create and update BOTH `AGENTS.md` and `CLAUDE.md` at the project root using the **fixed workspace-index template** below — the main project is a multi-project workspace, not a buildable project, so do NOT use free-form extraction or the `/init` skill here. Keep both files identical in their template-derived portions.

   **Template** — keep all fixed sections verbatim; fill only the scanned tables:

   ```markdown
   # <ProjectName>

   This is a multi-project workspace, **not** a buildable project. There is no build / test / lint / typecheck / task runner at the root.

   ## Directory Structure

   | Path | Description |
   |------|-------------|
   | `ai/config/rules/` | Rules & standards; apply when relevant |
   | `ai/config/skills/` | On-demand skills; invoke only when the user explicitly requests |
   | `ai/output/specs/` | Source-of-truth system behavior specs; read when needed or when requirements are unclear |
   | `ai/output/changes/archive/` | Archived change records (proposal/design); read design Decisions & proposal Why for past rationale, or for prior art when scoping a similar change — current behavior specs live in `ai/output/specs/` |
   | `ai/output/memories/` | Bad cases & lessons; read when facing blockers or seeking proven experience |
   | `modules/` | Independent projects, each its own git repo + guidance file |
   | `readonly-dependencies/` | Read-only dependency references; never modify |

   ## modules

   Each project under `modules/` is an independent git repository with its own git remote, toolchain, and `guidance file`.

   | Module Name | Path | Guidance File | Description |
   |-------------|------|---------------|-------------|
   | <module> | `modules/<module>` | `modules/<module>/AGENTS.md` | <description> |

   ## readonly-dependencies

   Stores **read-only references** to private dependencies for local reading. Not part of the build; depended on by modules.

   | Dependency Name | Path | Description |
   |-----------------|------|-------------|
   | <dependency> | `readonly-dependencies/<dependency>` | <description> |

   ## rules

   Rules & standards, apply when relevant.

   | Rule | Path | Description |
   |----------|------|-------------|
   | <rule> | `ai/config/rules/<rule_file>` | <description> |

   ## Workflow

   When working under `modules/`, read the standards in the following order:

   1. Module guidance file: `modules/<module>/AGENTS.md`
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
      gfs=""
      [ -f "${d}AGENTS.md" ] && gfs="AGENTS.md"
      [ -f "${d}CLAUDE.md" ] && gfs="${gfs:+$gfs + }CLAUDE.md"
      [ -z "$gfs" ] && gfs="AGENTS.md + CLAUDE.md"
      echo "M:$(basename "$d")|modules/$(basename "$d")|modules/$(basename "$d")/$gfs"
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
   - Apply the template to BOTH `AGENTS.md` and `CLAUDE.md`. For each file, if it already exists, regenerate from the template and compare; update ONLY on substantive changes (added/removed/renamed modules, dependencies, or rules). Keep both files identical in their template-derived portions.
   - Preserve any user-specific content outside the fixed template (e.g. custom development specs the user appended) in each file — update only the template-derived portions.

**Guardrails**
- Validate the git URL is accessible before cloning
- If the module directory already exists, ask the user before overwriting
- If cloning failed or was aborted, do not generate any guidance file

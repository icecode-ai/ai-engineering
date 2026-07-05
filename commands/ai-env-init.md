---
description: Initialize or update project environment for AI-assisted development
---

Initialize or update the project environment. Sets up the standard directory structure (`ai/`, `modules/`, `readonly-dependencies/`) and generates guidance files for the main project and each module.

**Module guidance file generation methodology**

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
     "ai/config"
     "ai/config/rules"
     "ai/config/skills"
     "ai/input"
     "ai/output/changes"
     "ai/output/changes/archive"
     "ai/output/memories"
     "ai/output/specs"
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
   entry="readonly-dependencies/*/*"
   if [ ! -f "$gitignore_file" ]; then
     printf '%s\n' "$entry" > "$gitignore_file"
     echo "Created .gitignore with readonly-dependencies entry"
   elif ! grep -qF "$entry" "$gitignore_file"; then
     printf '%s\n' "$entry" >> "$gitignore_file"
     echo "Added '${entry}' to .gitignore"
   else
     echo "'${entry}' already in .gitignore"
   fi

    echo "Environment initialized at: ${PROJECT_ROOT}"
   ```

2. **Generate guidance file for each module**

   For each directory under `modules/`, generate or update its guidance files following the **Module guidance file generation methodology** above (dual-write: keep `AGENTS.md` and `CLAUDE.md` in sync). Module guidance files do NOT carry the `readonly-dependencies/` marking.

   ```bash
   for module in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$module" ] || continue
     echo "Processing module: $(basename "$module")"
   done
   ```

3. **Generate main project guidance file**

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
- `readonly-dependencies/` is a read-only knowledge base — never write, modify, or delete files inside it
- Do NOT add `modules/` or `readonly-dependencies/` (top-level) to `.gitignore`; only `readonly-dependencies/*/*` (depth-2 contents) is ignored so dependency gitlinks stay trackable
- Synchronously maintain BOTH `AGENTS.md` and `CLAUDE.md` for the main project and each module

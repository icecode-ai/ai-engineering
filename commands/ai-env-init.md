---
description: Initialize or update project environment for AI-assisted development
---

Initialize or update the project environment. Sets up the standard directory structure (`ai/`, `modules/`, `readonly-dependencies/`) and generates guidance files for the main project and each module.

**Module guidance file generation methodology**

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

   config_file="${PROJECT_ROOT}/ai/config/spec-config.yaml"
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
     echo "Created: ai/config/spec-config.yaml"
   else
     echo "Exists: ai/config/spec-config.yaml"
   fi
   echo "Environment initialized at: ${PROJECT_ROOT}"
   ```

2. **Generate guidance file for each module**

   For each directory under `modules/`, generate or update its guidance file (`modules/$module/CLAUDE.md` for Claude Code, `modules/$module/AGENTS.md` for other agents) following the **Module guidance file generation methodology** above. Module guidance files do NOT carry the `readonly-dependencies/` marking.

   ```bash
   for module in "${PROJECT_ROOT}/modules"/*/; do
     [ -d "$module" ] || continue
     echo "Processing module: $(basename "$module")"
   done
   ```

3. **Generate main project guidance file**

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
- `readonly-dependencies/` is a read-only knowledge base — never write, modify, or delete files inside it
- Do NOT add `modules/` to `.gitignore` (but `readonly-dependencies/` should be added)
- For Claude Code, use `CLAUDE.md` as guidance file; for other agents, use `AGENTS.md`

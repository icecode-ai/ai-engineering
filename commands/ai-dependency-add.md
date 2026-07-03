---
description: Add a dependency project to the readonly-dependencies directory
argument-hint: <git-url> [<branch-name>]
---

Add a dependency project to the `readonly-dependencies/` directory. Dependencies are read-only knowledge bases — they provide context but should never be modified.

**Input**: Up to two arguments — the git repository URL, and an optional branch name (defaults to the default branch).

**Steps**

1. **Clone the repository into readonly-dependencies/**

   If `readonly-dependencies/$dep_name` already exists, ask the user whether to overwrite. On confirm, remove the existing directory and re-clone; on decline, abort.

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
   [ -z "$url" ] && { echo "Usage: /ai-dependency-add <git-url> [<branch>]"; exit 1; }
   dep_name="$(basename "$url" .git)"
   dep_dir="${PROJECT_ROOT}/readonly-dependencies/$dep_name"
   # An empty directory is treated as non-existent
   if [ -d "$dep_dir" ] && [ -n "$(ls -A "$dep_dir" 2>/dev/null)" ]; then
     echo "EXISTS: Dependency '$dep_name' already exists and is non-empty."
     echo "ACTION_REQUIRED: Ask the user whether to delete and re-add."
     echo "If confirmed, run: rm -rf \"$dep_dir\" then re-run clone."
     echo "If declined, abort."
     exit 1
   fi
   if [ -n "$branch" ]; then
     git clone --branch "$branch" "$url" "$dep_dir"
   else
     git clone "$url" "$dep_dir"
   fi
   ```

2. **Re-generate the main project guidance file**

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
- `readonly-dependencies/` is read-only — never modify files inside it during AI sessions
- If the dependency directory already exists, ask the user; on confirm, delete and re-clone; on decline, abort
- Validate the git URL is accessible before cloning

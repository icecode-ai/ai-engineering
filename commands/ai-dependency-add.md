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

   Generate or update the guidance file at the project root (`CLAUDE.md` for Claude Code, `AGENTS.md` for other agents) to include the new dependency context.

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
   Required marking: explicitly state `readonly-dependencies/` is a READ-ONLY knowledge base — never write, modify, or delete.
   Writing rules: short sections and bullets; include only what an agent would otherwise miss. Exclude generic advice, tutorials, obvious conventions, speculation. When in doubt, omit.

**Guardrails**
- `readonly-dependencies/` is read-only — never modify files inside it during AI sessions
- If the dependency directory already exists, ask the user; on confirm, delete and re-clone; on decline, abort
- Validate the git URL is accessible before cloning

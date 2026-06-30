---
description: Remove a module from the project
argument-hint: <module-name>
---

Remove a module from the `modules/` directory and update the project guidance.

**Input**: One argument — the module directory name to remove.

**Steps**

1. **Remove the module directory**

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   name="${1:-}"
   [ -z "$name" ] && { echo "Usage: /ai-module-remove <module-name>"; exit 1; }
   case "$name" in ..|*..*|/*) echo "Invalid module name '$name'"; exit 1;; esac
   if [ ! -d "${PROJECT_ROOT}/modules/$name" ]; then
     echo "Module '$name' not found"
     exit 1
   fi
   rm -rf "${PROJECT_ROOT}/modules/$name"
   ```

2. **Re-generate the main project guidance file**

   Generate or update the guidance file at the project root (`CLAUDE.md` for Claude Code, `AGENTS.md` for other agents) to reflect the removed module.

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
- Confirm with the user before removing, especially if there are uncommitted changes in the module
- If the module directory does not exist, inform the user and stop

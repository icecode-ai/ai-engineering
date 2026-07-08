---
name: goal-git-pull
description: Pull latest git content across MAIN, modules, and dependencies
argument-hint: [<target>]
disable-model-invocation: true
---

Pull the latest content from git remotes. Supports pulling for the main project, modules, and dependencies.

**Input**: One optional argument — the target scope. Defaults to `ALL`.

User-provided arguments: `$ARGUMENTS` (value is the target scope, optional; if empty, defaults to ALL)

| Target | Scope |
|--------|-------|
| `ALL` (default) | Main project + all modules + all dependencies |
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |
| `{dependency-name}` | A specific dependency in `readonly-dependencies/` |

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. Pull based on target scope

```bash
target="${1:-ALL}"
bash "ai/config/skills/goal-git-pull/scripts/pull.sh" "$target"
```

### 2. Resolve conflicts automatically

If `git pull` produced merge conflicts, automatically resolve them without prompting the user:

1. List conflicted files with `git diff --name-only --diff-filter=U` (run inside each repository that conflicted).
2. For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus the surrounding code and recent commit context to understand both sides' intent.
3. Edit the file to produce the correct merged result: combine non-overlapping changes from both sides; where they genuinely conflict, choose the semantically correct side based on the code's purpose. Remove all conflict markers.
4. Stage each resolved file with `git add <file>`.
5. Finalize the merge with `git commit` (default merge message) if the merge is still in progress.
6. Do not abort the merge, do not discard changes, do not ask for confirmation — resolve and proceed.

Repeat for every repository (MAIN, modules, and dependencies) that has conflicts.

**Outcome gate** (after step 1 + step 2): for each repository operated on, determine the final outcome:
- **No update** — output contains `Already up to date.` → skip guidance generation for that repository.
- **Failed** — the pull could not complete even after auto-resolution → skip.
- **Updated** — output shows a real pull (`Fast-forward`, `Updating ...`, `Merge made by ...`) → proceed for that repository.

Per-repo rule (including target `ALL`): generate the module guidance file only for modules whose outcome is **Updated**. Regenerate the main project guidance file only if at least one module was updated; if no repository was updated, **STOP** — do not generate any guidance file.

### 3. Generate guidance files for affected modules

For each module affected by this pull (i.e. when target is `ALL` or a specific module name) **and whose outcome is Updated**, generate or update its guidance files at `modules/$module/`. Skip dependencies — they are read-only and carry no guidance file. Skip modules whose outcome is No update or Failed.

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
Module guidance files do NOT carry the `readonly-dependencies/` marking.
Writing rules: short sections and bullets; include only what an agent would otherwise miss. Exclude generic advice, tutorials, obvious conventions, speculation. When in doubt, omit.

### 4. Generate main project guidance file (all targets)

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
bash "ai/config/skills/goal-git-pull/scripts/scan-entries.sh"
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

## Guardrails
- Skip repositories without a configured remote/upstream and inform the user
- If a repository produced no update (`Already up to date.`) or failed, skip guidance generation for it

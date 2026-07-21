---
name: goal-dependency-add
description: Add a dependency project to the readonly-dependencies directory
argument-hint: <git-url> [<branch-name>]
disable-model-invocation: true
---

Add a dependency project to the `readonly-dependencies/` directory. Dependencies are read-only knowledge bases — they provide context but should never be modified.

**Input**: Up to two arguments — the git repository URL, and an optional branch name (defaults to the default branch).

User-provided arguments: `$ARGUMENTS` (first value is the git URL; second value, if present, is the branch — otherwise the default branch is used)

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. Resolve missing arguments

Check `User-provided arguments` above. **If `$ARGUMENTS` is empty (no argument passed)**, use the **AskUserQuestion tool** (open-ended, no preset options) to ask the user for the git repository URL. Do not proceed until a valid URL is provided. **If `$ARGUMENTS` is non-empty**, take the first value as the git URL, skip the prompt, and proceed directly to step 2.

The `<branch-name>` argument is optional — do not prompt for it; if absent, the default branch is used.

### 2. Clone the repository into readonly-dependencies/

If `readonly-dependencies/$dep_name` already exists, ask the user whether to overwrite. On confirm, remove the existing directory and re-clone; on decline, abort.

Run the clone-and-register script (it resolves the project root itself; pass url and optional branch):

```bash
bash "ai/config/skills/goal-dependency-add/scripts/clone-and-register.sh" "$url" "$branch"
```

If the script prints `EXISTS:`, it also prints a `PATH:` line. Ask the user whether to delete and re-add. On confirm: `rm -rf "<that path>"` then re-run the script. On decline, abort.

### 3. Re-generate the main project guidance file

**Precondition**: the clone succeeded. If cloning failed (URL invalid/inaccessible) or the user declined to overwrite an existing dependency, **STOP** — do not generate the guidance file.

Synchronously create and update BOTH `AGENTS.md` and `CLAUDE.md` at the project root using the **fixed workspace-index template** below — the main project is a multi-project workspace, not a buildable project, so do NOT use free-form extraction or the `/init` skill here. Keep both files identical in their template-derived portions.

**Template** — keep all fixed sections verbatim; fill only the scanned tables:

```markdown
# <ProjectName>

This is a multi-project workspace, **not** a buildable project. There is no build / test / lint / typecheck / task runner at the root.

## Directory Structure

| Path | Description |
|------|-------------|
| `ai/config/rules/` | Rules & standards; apply when relevant |
| `ai/config/skills/` | On-demand skill library, not auto-loaded; each subdir is a skill — when a task may need one, discover the most suitable subdir and read its SKILL.md `description` to use |
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
bash "ai/config/skills/goal-dependency-add/scripts/scan-entries.sh"
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
- `readonly-dependencies/` is read-only — never modify files inside it during AI sessions
- If the dependency directory already exists, ask the user; on confirm, delete and re-clone; on decline, abort
- Validate the git URL is accessible before cloning
- If cloning failed or was aborted, do not generate the main project guidance file

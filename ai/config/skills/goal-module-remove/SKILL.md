---
name: goal-module-remove
description: Remove a module from the project
argument-hint: <module-name>
disable-model-invocation: true
---

Remove a module from the `modules/` directory and update the project guidance.

**Input**: One argument — the module directory name to remove.

User-provided arguments: `$ARGUMENTS` (value is the module directory name to remove)

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. Resolve missing argument

Check `User-provided arguments` above. **If `$ARGUMENTS` is non-empty**, use the value directly as the module-name and skip the listing and selection below. **If empty**, list available modules and ask the user to select:

```bash
if [ -d "modules" ]; then
  found=false
  for d in "modules"/*/; do
    [ -d "$d" ] || continue
    echo "$(basename "$d")"
    found=true
  done
  [ "$found" = false ] && echo "(no modules found)"
else
  echo "(no modules directory)"
fi
```

- If no modules exist, inform the user and **STOP** — do not proceed.
- Otherwise, use the **AskUserQuestion tool** to let the user select from the modules listed above (preset options, `multiple: false`; the user may type a custom name if needed).

### 2. Check for uncommitted changes and confirm removal

If the module directory is a git repository, check for uncommitted changes:

```bash
[ -d "modules/$name/.git" ] && git -C "modules/$name" status --porcelain
```

If the output is non-empty, inform the user: "Module '$name' has uncommitted changes that will be permanently lost."

Use the **AskUserQuestion tool** to confirm removal. If the user does not confirm, **STOP**.

### 3. Remove the module directory

```bash
bash "ai/config/skills/goal-module-remove/scripts/remove-and-unregister.sh" "$name"
```

### 4. Re-generate the main project guidance file

**Precondition**: removal succeeded. If removal failed (module not found / invalid name / aborted), **STOP** — do not generate the guidance file.

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
bash "ai/config/skills/goal-module-remove/scripts/scan-entries.sh"
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
- Confirm with the user before removing, especially if there are uncommitted changes in the module
- If the module directory does not exist, inform the user and stop
- If removal failed or was aborted, do not generate the main project guidance file

---
name: goal-git-checkout
description: Checkout a git branch across MAIN, modules, and dependencies
argument-hint: <target> <branch>
disable-model-invocation: true
---

Checkout a git branch across the project. Supports switching branches on the main project, modules, and dependencies.

**Input**: Two required arguments — the target scope and the branch name.

User-provided arguments: `$ARGUMENTS` (first value is the target, second is the branch)

| Target | Scope |
|--------|-------|
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |
| `{dependency-name}` | A specific dependency in `readonly-dependencies/` |

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. Resolve missing arguments

Check `User-provided arguments` above: if `$ARGUMENTS` provides a target → skip a; if it provides a branch → skip b; run the corresponding step only for whatever is missing. The bash `exit 1` in step 2 stays as a safety net.

**a. If `$ARGUMENTS` does not provide a target**, enumerate candidates and ask the user to select:

```bash
bash "ai/config/skills/goal-git-checkout/scripts/list-targets.sh"
```

Use the **AskUserQuestion tool** to let the user select from the candidates above (preset options, `multiple: false`; the user may type a custom name). The selected value becomes `<target>` (use the bare name for modules/dependencies, e.g. `module:foo` → `foo`).

**b. If `$ARGUMENTS` does not provide a branch** (after the target is determined), enumerate branches in the target repository and ask the user to select:

```bash
# $target_repo = the directory of the selected target (relative to workspace root):
#   MAIN → "."
#   module   → "modules/$target"
#   dependency → "readonly-dependencies/$target"
bash "ai/config/skills/goal-git-checkout/scripts/list-branches.sh" "$target_repo"
```

Use the **AskUserQuestion tool** to let the user select a branch from the list above (preset options, `multiple: false`; the user may type a custom branch name). If the target repository has no branches or is not a git repo, inform the user and **STOP**.

### 2. Checkout branch based on target scope

```bash
bash "ai/config/skills/goal-git-checkout/scripts/checkout.sh" "$target" "$branch"
```

### 3. Resolve checkout conflicts automatically

If `git checkout` reported that local uncommitted changes would be overwritten (the checkout did not complete), automatically recover without discarding local changes and without asking the user:

1. Identify the target repository that failed (MAIN, the module, or the dependency).
2. Save local changes (including untracked) in that repository with `git stash push -u -m "ai-git-checkout-autostash"`.
3. Retry `git checkout "$branch"` in the same repository.
4. Restore the stashed changes with `git stash pop`.
5. If `git stash pop` produces merge conflicts, resolve them automatically:
   - List conflicted files with `git diff --name-only --diff-filter=U`.
   - For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus surrounding code to understand both sides' intent.
   - Edit to produce the correct merged result: combine non-overlapping changes; where they genuinely conflict, choose the semantically correct side. Remove all conflict markers.
   - Stage each resolved file with `git add <file>`. No commit is needed — the resolved content stays in the working tree.
6. Do not discard local changes, do not abort, do not ask for confirmation.

If checkout failed for a reason other than local-change conflicts (e.g., the branch does not exist), report it and stop.

**Outcome gate** (after step 2 + step 3): determine the final checkout outcome for the target.
- **No update** — output contains `Already on '...'` (already on that branch). **STOP** — do not generate any guidance file.
- **Failed** — checkout could not complete (e.g., branch does not exist). **STOP**.
- **Updated** — output contains `Switched to ...`. Run the registry sync below, then proceed to step 4 (module targets only) and step 5.

**Registry sync** (on `Updated`, module/dependency targets only — MAIN has no registry entry): update the `branch` field in `ai/config/git.tsv` for the target path so the registry reflects the newly checked-out branch:

```bash
bash "ai/config/skills/goal-git-checkout/scripts/sync-registry.sh" "$target" "$branch"
```

### 4. Generate guidance file for the target module (module targets only)

If the target is a **module**, generate or update its guidance file at `modules/$target/`. Skip this step for `MAIN` and dependency targets — module guidance files are only for modules.

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

### 5. Generate main project guidance file (all targets)

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
bash "ai/config/skills/goal-git-checkout/scripts/scan-entries.sh"
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
- If checkout fails due to local-change conflicts, auto-recover via stash (step 3) without discarding changes
- Validate the branch exists on the target repository before switching
- If checkout produced no update (`Already on ...`) or failed, do not generate any guidance file

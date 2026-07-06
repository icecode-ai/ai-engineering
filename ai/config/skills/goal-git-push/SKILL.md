---
name: goal-git-push
description: Push git changes across MAIN and modules
argument-hint: [<target>]
disable-model-invocation: true
---

Push local commits to git remotes. Supports pushing for the main project and modules.

**IMPORTANT**: Never push the dependency repos under `readonly-dependencies/*/` directly — they are read-only knowledge bases. Recording their gitlink (commit pointer) in the MAIN repo is, however, expected behavior (see Step 3).

**Input**: One optional argument — the target scope. Defaults to `ALL`.

User-provided arguments: `$ARGUMENTS` (value is the target scope, optional; if empty, defaults to ALL)

| Target | Scope |
|--------|-------|
| `ALL` (default) | Main project + all modules |
| `MAIN` | Root project git repository |
| `{module-name}` | A specific module in `modules/` |

## Resolve PROJECT_ROOT

All script paths below are resolved from `PROJECT_ROOT` — the directory containing both `ai/` and `modules/`:

```bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

target="${1:-ALL}"
```

## Steps

### 1. Determine project root and target scope

See the `Resolve PROJECT_ROOT` block above. Derive `target` from `$ARGUMENTS` (default `ALL`).

### 2. If target is `ALL` or `MAIN` — check for incomplete changes before pushing

Before pushing the main project, verify there are no incomplete tasks or unarchived changes in `ai/output/changes/`:

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-git-push/scripts/check-incomplete-changes.sh"
```

If the check passes (all tasks complete, no missing artifacts), proceed to step 3 (stage and commit). If incomplete (script exits 1), **stop and prompt the user** to handle the outstanding changes before pushing.

### 3. Stage and commit uncommitted changes (with risk interception)

Before pulling, commit any uncommitted work in scope so later merge and push can proceed cleanly. Process each repository in scope — `MAIN`, or every module under `modules/` for `ALL`, or the single named module for `{module}`. For the `ALL` target, **process modules first, then MAIN** — this lets MAIN's `git add -A` capture each module's latest HEAD and refresh its gitlink. Recording `readonly-dependencies/<dep>` gitlinks in MAIN is expected; but never directly modify/pull/merge/push the dependency repos themselves.

a. List candidate files (modified, staged, and untracked, excluding gitignored) in the repository: `git status --porcelain --untracked-files=all`.
b. If there are no candidates, skip this repository.
c. **Risk interception** — for each candidate, check the following **exhaustive** list of risk categories:
   - Large file: size > 10 MB (`stat -f%z "$f"` on macOS / `stat -c%s "$f"` on Linux).
   - Suspicious filename: matches `*.env`, `*.pem`, `*.key`, `id_rsa`, `id_ed25519`, `*.p12`, `*.pfx`, `credentials*`, `secrets*`, `.npmrc`, `.pypirc`.
   - Secret content: text files containing `PRIVATE KEY`, `BEGIN RSA`, `BEGIN OPENSSH PRIVATE KEY`, `BEGIN PGP PRIVATE KEY`, or obvious high-entropy API keys/tokens (read the file to judge).
   - Unignored artifact paths: `node_modules/`, `dist/`, `build/`, `out/`, `target/`, `.next/`, `__pycache__/`, `coverage/`, `*.log`.

   **Nested git repos under `modules/*/` and `readonly-dependencies/*/` are expected by design** (each module/dependency is an independent git repo, added via `/ai-module-add` or `/ai-dependency-add`). They are NOT risk items — do NOT prompt (include/exclude/abort) for them. They will be recorded as gitlinks in step e.
d. **When a candidate is flagged, pause and ask the user per item**: "include" (add it anyway), "exclude" (skip it and keep it in the working tree), or "abort" (stop the entire push). Do not silently commit flagged files.
e. After all flagged items are resolved, stage the remaining candidates with `git add -A` (respects `.gitignore`); for any "exclude" item that was staged, unstage it with `git restore --staged <file>`. `git add -A` records `modules/<name>` and `readonly-dependencies/<dep>` as **gitlinks** (tree entry mode 160000 — a commit pointer to the nested repo's current HEAD); this is the desired behavior. MAIN stores only the commit pointer, never the nested repo's internal files. **Never create a `.gitmodules` file** — these are bare gitlinks, not submodules.
f. Generate a conventional-commit message from the diff and the active change in `ai/output/changes/` (the non-archived change matching this work): `feat(scope): <summary> [ai-change: <change-name>]`. Choose type (`feat`/`fix`/`refactor`/`docs`/`chore`/`test`) and scope from the diff. If multiple unrelated changes are present, split into multiple logical commits. If there is no active change, use `chore: <summary>` without the tag.
g. Commit with `git commit -m "<message>"`. Do not push yet.

### 4. Pull latest and sync mainline into the current branch

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-git-push/scripts/pull-and-merge.sh" "$target"
```

Only MAIN and modules are pulled and merged (matching push scope). Dependencies are never pulled/merged here.

### 5. Resolve conflicts automatically

If step 4 produced merge conflicts, automatically resolve them without prompting the user:

1. List conflicted files with `git diff --name-only --diff-filter=U` (run inside each repository that conflicted).
2. For each conflicted file, read the `<<<<<<<`, `=======`, and `>>>>>>>` sections plus the surrounding code and recent commit context to understand both sides' intent.
3. Edit the file to produce the correct merged result: combine non-overlapping changes from both sides; where they genuinely conflict, choose the semantically correct side based on the code's purpose. Remove all conflict markers.
4. Stage each resolved file with `git add <file>`.
5. Finalize the merge with `git commit` (default merge message) if the merge is still in progress.
6. Do not abort the merge, do not discard changes, do not ask for confirmation — resolve and proceed.
7. **Gitlink conflicts** under `modules/` or `readonly-dependencies/` (tree-level SHA conflicts, shown as `CONFLICT (submodule)` or a modified gitlink entry): resolve to the **current working-tree HEAD** of the nested repo (i.e. the commit the nested repo is actually checked out at). Record it with `git add modules/<name>` / `git add readonly-dependencies/<dep>`.

Repeat for every repository (MAIN and modules) that has conflicts.

### 6. Push based on target scope

```bash
bash "${PROJECT_ROOT}/ai/config/skills/goal-git-push/scripts/push.sh" "$target"
```

Pushing modules before MAIN ensures each gitlink's target commit exists on the module's remote before MAIN references it.

## Guardrails
- `readonly-dependencies/*/` repos are read-only: never directly pull/merge/push/modify them. Their gitlink may be recorded in MAIN and carried by MAIN's push — that is the only allowed interaction
- Never add `modules/` to `.gitignore` (per `/ai-env-init`); modules are tracked as gitlinks in MAIN
- Never create a `.gitmodules` file — modules and readonly-dependencies are recorded as bare gitlinks (commit pointers), not submodules
- For `ALL` or `MAIN` targets, always check `ai/output/changes/` for incomplete tasks or unarchived changes before pushing (fail-fast)
- Before pushing: stage+commit uncommitted work with risk interception (step 3), pull latest + merge mainline (step 4), and auto-resolve any conflicts (step 5)
- Risk interception (step 3) pauses to ask the user per flagged file (include/exclude/abort); never silently commit secrets, large files, or unignored artifacts
- Only committed changes are pushed — step 3 ensures uncommitted work (including AI-created files) is committed first
- If push fails due to remote divergence, inform the user and suggest re-running `/ai-git-push` (which now pulls and merges first)

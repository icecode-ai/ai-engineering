---
description: Initialize or update project environment for AI-assisted development
---

Initialize or update the project environment. Sets up the standard directory structure (`ai/`, `modules/`, `readonly-dependencies/`) and generates guidance files for the main project and each module.

## Module guidance file generation methodology

Dual-write policy: every module keeps BOTH `CLAUDE.md` and `AGENTS.md` in sync. Decide per module:
- **Both missing** → investigate (approach below) and generate BOTH `CLAUDE.md` and `AGENTS.md` with identical content.
- **`CLAUDE.md` exists, `AGENTS.md` missing** → copy `CLAUDE.md` to `AGENTS.md`.
- **`AGENTS.md` exists, `CLAUDE.md` missing** → copy `AGENTS.md` to `CLAUDE.md`.
- **Both exist** → skip; do not regenerate.

### How to investigate

- Read `README*`, root manifests, workspace config, lockfiles; build/test/lint/formatter/typecheck/codegen config; CI workflows; existing instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `.cursorrules`, `.github/copilot-instructions.md`); `opencode.json`.
- Prefer executable sources of truth over prose; if docs conflict with config/scripts, trust the executable source.
- If architecture is still unclear, inspect a few representative code files for real entrypoints and package boundaries.

### What to extract

High-signal, repo-specific only:
- exact developer commands, especially non-obvious ones; how to run a single test/package/focused verification
- required command order when it matters (e.g. `lint -> typecheck -> test`)
- monorepo/multi-package boundaries, major directory ownership, real app/library entrypoints
- framework/toolchain quirks: generated code, migrations, codegen, build artifacts, env loading, dev servers, deploy flow
- repo-specific style/workflow conventions differing from defaults; testing quirks (fixtures, integration prerequisites, snapshots, services, flaky suites)
- constraints from existing instruction files worth preserving

### Preserve user-specific content

Keep the user's special references/sections (e.g. development specs, custom conventions); update only the factual, project-derived portions.

### Writing rules

Short sections and bullets; include only what an agent would otherwise miss. Exclude generic advice, tutorials, obvious conventions, speculation. When in doubt, omit.

## Steps

### 1. Discover project root, create standard directories, and configure .gitignore

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
  "ai/input/common"
  "ai/input/common/references"
  "ai/input/jim"
  "ai/input/jim/0"
  "ai/input/jim/1"
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

### 2. Sync plugin `ai/` templates into project `ai/`

The plugin ships template content under its own `ai/` (currently `ai/config/rules/**`, `ai/config/skills/**`, plus `ai/config/git.tsv` and `ai/config/spec-config.yaml` as starters). Sync them into the project's `ai/` so the project has the standard rules/skills.

- `config/git.tsv`, `config/spec-config.yaml`, and each file under `config/rules/`: copy ONLY if absent in the project — once present they are the user's owned content, never overwritten.
- `config/skills/`: sync from the plugin — new skills are copied and shared skills are overwritten with the plugin version, but skills that exist only in the project (user's custom skills) are never deleted.

**Locate `PLUGIN_ROOT`**: resolve at runtime — you (the Agent) know where you loaded this command from; the plugin root is the parent of `commands/` (it also contains `skills/`, `agents/`, `ai/`). Set `PLUGIN_ROOT` in the script below to that absolute path before running.

```bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

PLUGIN_ROOT=""

SRC="${PLUGIN_ROOT}/ai"
DST="${PROJECT_ROOT}/ai"

if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$SRC" ]; then
  echo "PLUGIN_ROOT not set or plugin ai/ missing at '${SRC}' — skip template sync."
  echo "Set PLUGIN_ROOT to the plugin root (parent of commands/) and re-run this step."
elif ! command -v rsync >/dev/null 2>&1; then
  echo "rsync not available — skip template sync (install rsync to enable)."
else
  # git.tsv & spec-config.yaml: copy only if absent
  for f in config/git.tsv config/spec-config.yaml; do
    if [ -f "$SRC/$f" ] && [ ! -f "$DST/$f" ]; then
      mkdir -p "$(dirname "$DST/$f")"
      cp "$SRC/$f" "$DST/$f"
      echo "copied (new): $f"
    else
      echo "skip (exists or no source): $f"
    fi
  done

  # rules/: copy each file only if absent (user-owned once present)
  if [ -d "$SRC/config/rules" ]; then
    find "$SRC/config/rules" -type f -print0 | while IFS= read -r -d '' rulefile; do
      rel="${rulefile#$SRC/}"
      if [ ! -f "$DST/$rel" ]; then
        mkdir -p "$(dirname "$DST/$rel")"
        cp "$rulefile" "$DST/$rel"
        echo "copied (new): $rel"
      else
        echo "skip (exists): $rel"
      fi
    done
  fi

  # skills/: sync (copy new + overwrite shared, preserve user's custom skills)
  if [ -d "$SRC/config/skills" ]; then
    rsync -a "$SRC/config/skills/" "$DST/config/skills/"
    echo "synced: config/skills/ (updated, user skills preserved)"
  fi

  echo "Template sync complete."
fi
```

### 3. Materialize registered repos from `ai/config/git.tsv`

After creating directories, clone each module/dependency registered in `ai/config/git.tsv` so later steps can read their code. The registry is a tab-separated file (`# path<TAB>url<TAB>branch`); each row records a gitlink path, its remote URL, and branch. The gitlink SHA (mode 160000) in MAIN's tree pins the exact commit; the registry supplies URL + branch.

For each row: if the path directory is already populated, skip (re-init safe); otherwise clone and land on the recorded branch at the recorded gitlink SHA, so downstream reproduces the exact branch + commit upstream recorded. Skip gracefully when MAIN is not yet a git repo (first init before any commit), or the registry is absent or empty (no non-comment rows).

```bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

registry="ai/config/git.tsv"
if [ ! -s "$registry" ] || ! awk -F'\t' '{if($1!="" && $1 !~ /^#/){f=1; exit}} END{exit !f}' "$registry" 2>/dev/null; then
  echo "No ai/config/git.tsv (missing or empty) — skip materialization."
elif ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "MAIN not a git repo yet — skip materialization."
else
  while IFS=$'\t' read -r path url branch; do
    case "$path" in ''|\#*) continue;; esac
    if [ -e "$path" ] && [ -n "$(ls -A "$path" 2>/dev/null)" ]; then
      echo "skip (populated): $path"
      continue
    fi
    mkdir -p "$path"
    sha="$(git ls-tree HEAD -- "$path" 2>/dev/null | awk '$2=="commit"{print $3}' || true)"
    if [ -n "$sha" ]; then
      if git clone "$url" "$path" && git -C "$path" checkout -B "$branch" "$sha"; then
        echo "materialized (branch $branch @ $sha): $path"
      else
        echo "FAILED: $path — check url/branch/sha"
      fi
    else
      if git clone --branch "$branch" "$url" "$path"; then
        echo "materialized (branch $branch @ tip): $path"
      else
        echo "FAILED: $path — check url/branch"
      fi
    fi
  done < "$registry"
fi
```

### 4. Generate guidance file for each module

For each directory under `modules/`, generate or update its guidance files following the **Module guidance file generation methodology** above (dual-write: keep `AGENTS.md` and `CLAUDE.md` in sync). Module guidance files do NOT carry the `readonly-dependencies/` marking.

```bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

for module in "${PROJECT_ROOT}/modules"/*/; do
  [ -d "$module" ] || continue
  echo "Processing module: $(basename "$module")"
done
```

### 5. Generate main project guidance file

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

Stores **read-only references** to private dependencies for local reading. Not part of the build; depended on by modules. When you need to understand the technical frameworks, references, or other knowledge that `modules/<module>` depends on, prioritize reading the relevant content under this directory first; if not found, then traverse other directories or search the web.

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
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

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

## Guardrails

- `readonly-dependencies/` is a read-only knowledge base — never write, modify, or delete files inside it
- Do NOT add `modules/` or `readonly-dependencies/` (top-level) to `.gitignore`; only `readonly-dependencies/*/*` (depth-2 contents) is ignored so dependency gitlinks stay trackable
- `ai/config/git.tsv` is the tracked registry of module/dependency repos (path → url + branch); keep it committed — `ai-env-init` uses it to materialize gitlink repos, and `ai-module-add`/`ai-dependency-add`/`ai-module-remove`/`ai-dependency-remove`/`ai-git-checkout` keep it in sync
- Synchronously maintain BOTH `AGENTS.md` and `CLAUDE.md` for the main project and each module

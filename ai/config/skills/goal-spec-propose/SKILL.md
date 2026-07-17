---
name: goal-spec-propose
description: Propose a new change — create it and generate all artifacts in one step
argument-hint: [<change-name-or-description>]
disable-model-invocation: true
---

Propose a new change — create the change directory and generate all artifacts (proposal, specs, design, tasks) in one step.

When ready to implement, run `/ai-spec-apply`.

**Input** (optional): The change name (kebab-case) OR a description of what the user wants to build — passed via the `/ai-spec-propose` command argument or specified directly in the prompt.

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. If no input provided, ask what they want to build

Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
> "What change do you want to work on? Describe what you want to build or fix."

From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

**IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

### 2. Create the change directory

```bash
bash "ai/config/skills/goal-spec-propose/scripts/create-change.sh" "$name"
```

If it prints `EXISTS:`, ask the user whether to continue with the existing change or create a new one with a different name.

### 3. Check artifact status

```bash
bash "ai/config/skills/goal-spec-propose/scripts/check-artifacts.sh" "$name"
```

### 4. Load project config (optional)

Read `ai/config/spec-config.yaml` if it exists. If present:
- `context` — apply as background to **every** artifact you generate (proposal, specs, design, tasks).
- `rules` — for each artifact you generate, apply `rules[<artifactId>]` as mandatory constraints. Valid IDs: `proposal`, `specs`, `design`, `tasks`.

If the file is absent, proceed normally (default schema is `spec-driven`).

### 5. Create artifacts in dependency order

Use the **TodoWrite tool** to track progress through the artifacts. Use the **Write tool** to create each filled artifact file (write real content, not just the skeleton).

**a. Create proposal.md** (what & why) at `$change_dir/proposal.md`:

```markdown
## Why
<!-- Explain the motivation for this change -->

## What Changes
<!-- Describe what will change -->

## Capabilities

### New Capabilities
- `<name>`: <description>

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact
<!-- Affected code, APIs, dependencies, systems -->
```

Fill in the template with your analysis of the user's request. Read any existing context files for reference.

**b. Read completed proposal and create specs/**

Create one or more spec files under `$change_dir/specs/<capability>/spec.md` based on proposal analysis (use the **Write tool**; it creates parent directories as needed). A spec file is a **delta** — it describes only what this change adds, modifies, removes, or renames for that capability, not the full spec.

Use only the sections below that apply (a brand-new capability uses only `## ADDED Requirements`; modifying an existing one uses `## MODIFIED` / `## REMOVED` / `## RENAMED` as needed). **Never use `## ADDED Requirements` for a requirement that already exists** — that creates duplicates on merge; use `## MODIFIED Requirements` instead.

```markdown
## ADDED Requirements
### Requirement: <!-- name -->
<!-- Requirement text using SHALL / MUST normative keywords -->
#### Scenario: <!-- name -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

## MODIFIED Requirements
### Requirement: <!-- existing name -->
<!-- The FULL replacement content (not a diff): the complete updated requirement text + all scenarios.
     Any scenario from the main spec that you omit here is DROPPED on merge, so restate every scenario
     you want to keep, then add/change the new ones. -->
#### Scenario: <!-- name -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

## REMOVED Requirements
### Requirement: <!-- existing name -->
**Reason:** <!-- why it is being removed -->
**Migration:** <!-- how existing data/callers/consumers are handled — never omit, write "None" if truly N/A -->

## RENAMED Requirements
FROM: <!-- old requirement name -->
TO: <!-- new requirement name -->
<!-- If the content also changes, follow this block with a ## MODIFIED Requirements entry using the NEW name. -->
```

**Spec writing rules (mandatory):**
- Use **SHALL** / **MUST** normative keywords in requirement bodies; keep them testable.
- Every requirement MUST have at least one `#### Scenario:` (4 hashes) with WHEN/THEN.
- A delta spec touches ONE capability per file under `specs/<capability>/spec.md`.
- `## MODIFIED Requirements` provides the **full replacement** content — the merge replaces the whole requirement, so include every scenario you want to keep.
- `## REMOVED Requirements` MUST include both **Reason** and **Migration**.
- `## RENAMED Requirements` uses `FROM:`/`TO:`; if the body also changes, add a MODIFIED entry under the new name.
- Apply operations in order RENAMED → REMOVED → MODIFIED → ADDED at archive time (the archive skill enforces this).

**c. Create design.md** (how) at `$change_dir/design.md`:

```markdown
## Context

## Goals / Non-Goals
**Goals:**
**Non-Goals:**

## Decisions

## Risks / Trade-offs

## Migration Plan
<!-- Data/API/config migrations needed, in order. Write "None" if not applicable. -->

## Open Questions
<!-- Unresolved decisions that need input before or during implementation. Write "None" if clear. -->
```

Fill in the template with architecture decisions, technical approach, and trade-offs. The Migration Plan and Open Questions sections are required (write "None" when there is nothing to migrate or no open questions) so downstream tasks and reviewers can see migration steps and pending decisions explicitly.

**d. Create tasks.md** (implementation steps) at `$change_dir/tasks.md` — **use fine-grained, execution-ready task structure** so `/ai-spec-apply` can dispatch one subagent per task with everything it needs:

```markdown
# <Change Name> Implementation Tasks

**Goal:** <one sentence>
**Architecture:** <2-3 sentences>

## Global Constraints
<project-wide requirements — version floors, dependency limits, naming/copy rules — one line each, exact values verbatim from the spec. Every task implicitly includes this section.>

## 1. <Task Group Name>

### Task 1: <Component Name>

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing:123-145`
- Test: `tests/exact/path/to/test`

**Interfaces:**
- Consumes: <what this task uses from earlier tasks — exact signatures>
- Produces: <what later tasks rely on — function names, param/return types>

**Parallelizable:** no

- [ ] **Step 1: Write the failing test** (2-5 min)
- [ ] **Step 2: Run test to verify it fails** — `pytest tests/path -v`, expected FAIL
- [ ] **Step 3: Write minimal implementation**
- [ ] **Step 4: Run test to verify it passes** — `pytest tests/path -v`, expected PASS

> No commit step — in `/ai-spec-apply` neither the controller nor the implementer touches git; the user stages and commits when ready.

### Task 2: ...
```

**Task-granularity rules (mandatory):**
- Each task is the smallest unit that carries its own test cycle and a fresh reviewer's gate (2-5 minutes per step). Fold setup/scaffolding/docs into the task whose deliverable needs them.
- **Exact file paths always** (no "the appropriate file"). **Complete code in every step** that changes code. **Exact commands with expected output**.
- **No placeholders**: never write "TBD", "TODO", "implement later", "add appropriate error handling", "similar to Task N" (repeat the code), or steps that describe what without showing how.
- Mark `**Parallelizable:** yes` only for tasks with no shared state and no file overlap with other tasks (enables **parallel dispatch** in `/ai-spec-apply` — independent implementers run concurrently within a wave). Default `no` for tasks that depend on earlier tasks' Interfaces. The `**Consumes:**`/`**Produces:**` blocks MUST be accurate: parallel dispatch gates on satisfied Consumes, so a wrong or missing dependency can dispatch a task before its interfaces are ready.
- Order tasks by dependency. Each task ends with an independently testable deliverable.
- Keep spec-compliance testable: each task should map to one or more spec scenarios.

### 6. Show final status

```bash
bash "ai/config/skills/goal-spec-propose/scripts/check-artifacts.sh" "$name"
```

## Output

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Run `/ai-spec-apply $name` to start implementing."

## Artifact Creation Guidelines

- Fill in templates with real content based on the user's request and codebase analysis
- Read dependency artifacts for context before creating new ones
- If context is critically unclear, ask the user — but prefer making reasonable decisions to keep momentum
- Verify each artifact file exists after writing before proceeding to next

## Guardrails
- Create ALL artifacts needed for implementation (proposal, specs, design, tasks)
- Always read dependency artifacts before creating a new one
- If a change with that name already exists, ask if user wants to continue it or create a new one
- The `.spec.yaml` metadata file is required for change tracking
- tasks.md MUST follow the fine-grained structure above (exact paths, complete code, no placeholders, Parallelizable flag) — this is what `/ai-spec-apply`'s subagent-driven execution depends on

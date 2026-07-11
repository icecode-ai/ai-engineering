---
name: goal-requirements-explore
description: Explore and complete an unclear or one-line requirement into a full, unambiguous requirement by reading project context
argument-hint: <requirement-description-or-file-or-url>
disable-model-invocation: true
---

Explore and complete an unclear or one-line requirement into a full, unambiguous requirement by progressively reading project context. The output is a structured requirement document ready for downstream use.

**Input** (required): The argument is the requirement, in one of three forms:
- A requirement description (text)
- A requirement file path (e.g., `ai/input/jim/0/prd.md`)
- A requirement URL (web link)

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Steps

### 1. Parse the input

Determine the input type and obtain the raw requirement text:

- **File path** — use the **Read tool** to read the file content
- **URL** — use the **WebFetch tool** to fetch the content
- **Text description** — use directly

### 2. Identify relevant modules and dependencies

Before diving into context, determine which parts of the codebase are relevant to this requirement.

Use the **Glob tool** with pattern `modules/*/` to list all modules, and `readonly-dependencies/*/` to list all dependencies.

For each module (and dependency), read its guidance file (`README.md`, `AGENTS.md`, or `CLAUDE.md` — whichever exists) to understand its purpose and tech stack. Based on the requirement text, determine which modules and dependencies are **relevant**.

If only one module exists and the requirement clearly relates to it, skip the scan and use it directly.

### 3. Progressive context exploration (waterfall — stop early when clear)

Explore project context in **priority order**. After each step, assess whether the requirement is now clear and unambiguous. If yes, **stop** — do not proceed to deeper steps. Each step below uses the relevant modules/dependencies identified in Step 2.

#### Step 3.1: Module guidance files

Read the `README.md`, `AGENTS.md`, or `CLAUDE.md` of relevant modules under `modules/`. These files contain high-signal project facts — architecture boundaries, tech stack, conventions — that often clarify intent immediately.

If the requirement is now clear, stop.

#### Step 3.2: Spec knowledge

Read relevant spec files under `ai/output/specs/`. Use the **Glob tool** with pattern `ai/output/specs/*/spec.md` to discover available specs, then read those matching the requirement's domain.

Specs are the source-of-truth for current system behavior — they reveal what already exists and how it works.

If the requirement is now clear, stop.

#### Step 3.3: Memories (past experience)

Read relevant memory files under `ai/output/memories/`. Use the **Glob tool** with pattern `ai/output/memories/*.md` to discover available memories, then read those related to the requirement.

Memories capture bad cases and lessons learned — they prevent repeating mistakes and surface hidden constraints.

If the requirement is now clear, stop.

#### Step 3.4: Archived change records

Read relevant archived changes under `ai/output/changes/archive/`. Use the **Glob tool** with pattern `ai/output/changes/archive/*/*.md` to discover past changes, then read those related to the requirement (focus on `proposal.md` for the "why" and `design.md` for decisions).

Archived changes reveal prior art and past rationale — useful when scoping a similar change.

If the requirement is now clear, stop.

#### Step 3.5: Module code

Read relevant code or other content in the relevant modules under `modules/`. Use **Grep** and **Glob** to find files related to the requirement's keywords, then read them.

This is the deepest level of module investigation — only needed when higher-level context was insufficient.

If the requirement is now clear, stop.

#### Step 3.6: Dependency code

Read relevant code or other content in the relevant dependencies under `readonly-dependencies/`. Use **Grep** and **Glob** to find files related to the requirement, then read them.

Dependencies are read-only references — never modify them, only read for understanding.

### 4. Synthesize the complete requirement

Based on everything gathered, produce a structured requirement document with the following sections:

```markdown
## Requirement: <title>

### Background
<!-- Why this requirement exists, what problem it solves -->

### Objective
<!-- What the user wants to achieve, in one or two sentences -->

### Functional Requirements
<!-- What the system should do, as a list of concrete, testable items -->
- <requirement 1>
- <requirement 2>

### Non-Functional Requirements
<!-- Performance, security, compatibility, etc. -->
- <requirement 1>

### Scope
**In scope:**
- <item>
**Out of scope:**
- <item>

### Affected Modules
<!-- Which modules/components are involved -->
- `modules/<module>`: <how it's affected>

### Constraints
<!-- Technical or business constraints discovered during exploration -->

### Assumptions
<!-- Assumptions made when the requirement was ambiguous. The user should review these. -->
- <assumption 1>

### Open Questions
<!-- Items that are still unclear after exploration. Empty if none. -->
```

**Filling guidelines:**
- Fill every section with real content derived from the exploration — not placeholders
- If a section has no content, write "None" rather than leaving it empty
- When the requirement was ambiguous even after all 6 steps, make **reasonable assumptions**, document them in **Assumptions**, and proceed — do not block or ask the user
- List anything still genuinely unclear under **Open Questions** (this is informational, not blocking)

## Output

Present the complete requirement document as text to the user. This is the skill's final output.

## Guardrails

- **Read-only**: never write code, create files, or implement features. This skill explores and clarifies — it does not build.
- **Early exit**: stop exploring the moment the requirement becomes clear. Do not read more context than needed.
- **Ground in reality**: base the requirement on actual codebase context, not assumptions about how the code might work.
- **Document all assumptions**: when guessing, say so explicitly in the Assumptions section so the user can verify.
- **Never modify `readonly-dependencies/`**: only read for understanding.

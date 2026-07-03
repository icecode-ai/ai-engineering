---
description: Propose a new change - create it and generate all artifacts in one step
argument-hint: [<change-name-or-description>]
---

Propose a new change — create the change directory and generate all artifacts (proposal, design, tasks) in one step.

When ready to implement, run `/ai-spec-apply`.

---

**Input**: The argument after `/ai-spec-propose` is the change name (kebab-case), OR a description of what the user wants to build.

**Steps**

1. **If no input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**

   ```bash
   set -euo pipefail
   PROJECT_ROOT="$(pwd)"
   while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
     PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
   done
   [ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
   cd "$PROJECT_ROOT"

   name="${1:-}"
   [ -z "$name" ] && { echo "Usage: /ai-spec-propose <change-name-or-description>"; exit 1; }
   change_dir="${PROJECT_ROOT}/ai/output/changes/$name"

   # Check if change already exists
   if [ -d "$change_dir" ] && [ "$(ls -A "$change_dir" 2>/dev/null)" ]; then
     echo "EXISTS: Change '$name' already exists."
     echo "Ask user: continue with existing change, or create a new one with a different name."
     exit 1
   fi

   mkdir -p "$change_dir"

   {
     echo 'schema: spec-driven'
     echo "created: $(date +%Y-%m-%d)"
   } > "$change_dir/.openspec.yaml"
   ```

3. **Check artifact status**

   Determine which artifacts already exist and which need to be created:

   ```bash
   change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
   for artifact in proposal.md design.md tasks.md; do
     if [ -f "$change_dir/$artifact" ]; then
       echo "✓ $artifact (done)"
     else
       echo "○ $artifact (pending)"
     fi
   done

   # Check specs directory
   specs_dir="$change_dir/specs"
   if [ -d "$specs_dir" ] && [ "$(ls -A "$specs_dir" 2>/dev/null)" ]; then
     echo "✓ specs/ (done)"
   else
     echo "○ specs/ (pending)"
   fi
   ```

4. **Load project config (optional)**

   Read `${PROJECT_ROOT}/ai/config/spec-config.yaml` if it exists. If present:
   - `context` — apply as background to **every** artifact you generate (proposal, specs, design, tasks).
   - `rules` — for each artifact you generate, apply `rules[<artifactId>]` as mandatory constraints. Valid IDs: `proposal`, `specs`, `design`, `tasks`.

   If the file is absent, proceed normally (default schema is `spec-driven`).

5. **Create artifacts in dependency order**

   Use the **TodoWrite tool** to track progress through the artifacts.

   **a. Create proposal.md** (what & why)

   ```bash
   {
     echo '## Why'
     echo '<!-- Explain the motivation for this change -->'
     echo ''
     echo '## What Changes'
     echo '<!-- Describe what will change -->'
     echo ''
     echo '## Capabilities'
     echo ''
     echo '### New Capabilities'
     echo '- `<name>`: <description>'
     echo ''
     echo '### Modified Capabilities'
     echo '- `<existing-name>`: <what requirement is changing>'
     echo ''
     echo '## Impact'
     echo '<!-- Affected code, APIs, dependencies, systems -->'
   } > "$change_dir/proposal.md"
   ```

   Fill in the template with your analysis of the user's request. Read any existing context files for reference.

   **b. Read completed proposal and create specs/**

   ```bash
   mkdir -p "$change_dir/specs"
   ```

   Create one or more spec files under `specs/` based on proposal analysis:

   ```markdown
   ## ADDED Requirements
   ### Requirement: <!-- name -->
   <!-- text -->
   #### Scenario: <!-- name -->
   - **WHEN** <!-- condition -->
   - **THEN** <!-- expected outcome -->
   ```

   **c. Create design.md** (how)

   ```bash
   {
     echo '## Context'
     echo ''
     echo '## Goals / Non-Goals'
     echo '**Goals:**'
     echo '**Non-Goals:**'
     echo ''
     echo '## Decisions'
     echo ''
     echo '## Risks / Trade-offs'
   } > "$change_dir/design.md"
   ```

   Fill in the template with architecture decisions, technical approach, and trade-offs.

   **d. Create tasks.md** (implementation steps)

   ```bash
   {
     echo '## 1. <!-- Task Group Name -->'
     echo '- [ ] 1.1 <!-- Task description -->'
     echo '- [ ] 1.2 <!-- Task description -->'
     echo ''
     echo '## 2. <!-- Task Group Name -->'
     echo '- [ ] 2.1 <!-- Task description -->'
     echo '- [ ] 2.2 <!-- Task description -->'
   } > "$change_dir/tasks.md"
   ```

   Fill in with concrete, actionable implementation tasks derived from the design and specs.

6. **Show final status**

   ```bash
   echo "=== Change: $name ==="
   for artifact in proposal.md design.md tasks.md; do
     if [ -f "$change_dir/$artifact" ]; then
       echo "✓ $artifact"
     else
       echo "✗ $artifact (missing)"
     fi
   done
   if [ -d "$change_dir/specs" ]; then
     echo "✓ specs/"
   fi
   echo "All artifacts created! Ready for implementation."
   ```

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Run `/ai-spec-apply $name` to start implementing."

**Artifact Creation Guidelines**

- Fill in templates with real content based on the user's request and codebase analysis
- Read dependency artifacts for context before creating new ones
- If context is critically unclear, ask the user — but prefer making reasonable decisions to keep momentum
- Verify each artifact file exists after writing before proceeding to next

**Guardrails**
- Create ALL artifacts needed for implementation (proposal, specs, design, tasks)
- Always read dependency artifacts before creating a new one
- If a change with that name already exists, ask if user wants to continue it or create a new one
- The `.openspec.yaml` metadata file is required for change tracking

---
description: Enter explore mode - think through ideas, investigate problems, clarify requirements
---

Enter explore mode. Think deeply. Visualize freely. Follow the conversation wherever it goes.

**IMPORTANT: Explore mode is for thinking, not implementing.** You may read files, search code, and investigate the codebase, but you must NEVER write code or implement features. If the user asks you to implement something, remind them to exit explore mode first and create a change proposal. You MAY create AI artifacts (proposals, designs, specs) if the user asks—that's capturing thinking, not implementing.

**This is a stance, not a workflow.** There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore.

**Input**: The argument after `/ai-spec-explore` is whatever the user wants to think about. Could be:
- A vague idea: "real-time collaboration"
- A specific problem: "the auth system is getting unwieldy"
- A change name: "add-dark-mode" (to explore in context of that change)
- A comparison: "postgres vs sqlite for this"
- Nothing (just enter explore mode)

---

## The Stance

- **Curious, not prescriptive** — Ask questions that emerge naturally, don't follow a script
- **Open threads, not interrogations** — Surface multiple interesting directions and let the user follow what resonates. Don't funnel them through a single path of questions.
- **Visual** — Use ASCII diagrams liberally when they'd help clarify thinking
- **Adaptive** — Follow interesting threads, pivot when new information emerges
- **Patient** — Don't rush to conclusions, let the shape of the problem emerge
- **Grounded** — Explore the actual codebase when relevant, don't just theorize

---

## What You Might Do

Depending on what the user brings, you might:

**Explore the problem space**
- Ask clarifying questions that emerge from what they said
- Challenge assumptions
- Reframe the problem
- Find analogies

**Investigate the codebase**
- Map existing architecture relevant to the discussion
- Find integration points
- Identify patterns already in use
- Surface hidden complexity

**Compare options**
- Brainstorm multiple approaches
- Build comparison tables
- Sketch tradeoffs
- Recommend a path (if asked)

**Visualize**
```
┌─────────────────────────────────────────┐
│     Use ASCII diagrams liberally        │
├─────────────────────────────────────────┤
│                                         │
│      ┌────────┐         ┌────────┐      │
│      │ State  │────────▶│ State  │      │
│      │   A    │         │   B    │      │
│      └────────┘         └────────┘      │
│                                         │
│   System diagrams, state machines,      │
│   data flows, architecture sketches,    │
│   dependency graphs, comparison tables  │
│                                         │
└─────────────────────────────────────────┘
```

**Surface risks and unknowns**
- Identify what could go wrong
- Find gaps in understanding
- Suggest spikes or investigations

---

## Check for Context

At the start, quickly check what changes exist:

```bash
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"
ls -1 "${PROJECT_ROOT}/ai/changes/" 2>/dev/null | grep -v '^archive$' || echo "No active changes found"
```

This tells you if there are active changes and their names.

If the user mentioned a specific change name, read its artifacts for context.

---

## When a Change Exists

If the user mentions a change or you detect one is relevant:

1. **Check artifact status**
   ```bash
   change_dir="${PROJECT_ROOT}/ai/changes/$name"
   for artifact in proposal.md design.md tasks.md; do
     if [ -f "$change_dir/$artifact" ]; then
       echo "✓ $artifact"
     else
       echo "○ $artifact (not yet created)"
     fi
   done
   ```
   Read existing artifacts for context.

2. **Reference them naturally in conversation**
   - "Your design mentions using Redis, but we just realized SQLite fits better..."
   - "The proposal scopes this to premium users, but we're now thinking everyone..."

3. **Offer to capture when decisions are made**

   | Insight Type | Where to Capture |
   |---|---|
   | New requirement discovered | `ai/specs/<capability>/spec.md` |
   | Requirement changed | `ai/specs/<capability>/spec.md` |
   | Design decision made | `ai/changes/<name>/design.md` |
   | Scope changed | `ai/changes/<name>/proposal.md` |
   | New work identified | `ai/changes/<name>/tasks.md` |

4. **The user decides** — Offer and move on. Don't pressure. Don't auto-capture.

---

## What You Don't Have To Do

- Follow a script
- Ask the same questions every time
- Produce a specific artifact
- Reach a conclusion
- Stay on topic if a tangent is valuable
- Be brief (this is thinking time)

---

## Ending Discovery

There's no required ending. Discovery might:
- **Flow into a proposal**: "Ready to start? I can create a change proposal."
- **Result in artifact updates**: "Updated design.md with these decisions"
- **Just provide clarity**: User has what they need, moves on
- **Continue later**: "We can pick this up anytime"

When things crystallize, you might offer a summary — but it's optional. Sometimes the thinking IS the value.

### Offer to create a change

When exploration reaches a natural conclusion (decisions crystallized, user seems ready to move forward), **ask the user whether they want to create a change**. For example:

> "Exploration looks complete. Would you like to create a change proposal from this? Reply to confirm, or run `/ai-spec-propose` directly."

If the user declines or wants to continue exploring, respect that — no pressure.

If the user replies affirmatively — e.g. "创建", "创建变更", "创建变更吧", "创建吧", "好", "yes", "create" — **directly create the change** by executing the steps below. Derive a kebab-case change name from the exploration topic, create the change directory, and generate all artifacts (proposal, specs, design, tasks) in one step.

If the user runs `/ai-spec-propose` directly, that command handles the full flow independently.

**Step 1. Derive change name**

From the exploration topic, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

**Step 2. Create the change directory**

```bash
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"

name="<derived-kebab-case-name>"
change_dir="${PROJECT_ROOT}/ai/changes/$name"

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

**Step 3. Check artifact status**

```bash
change_dir="${PROJECT_ROOT}/ai/changes/$name"
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

**Step 4. Load project config (optional)**

Read `${PROJECT_ROOT}/ai/config.yaml` if it exists. If present:
- `context` — apply as background to **every** artifact you generate (proposal, specs, design, tasks).
- `rules` — for each artifact you generate, apply `rules[<artifactId>]` as mandatory constraints. Valid IDs: `proposal`, `specs`, `design`, `tasks`.

If the file is absent, proceed normally (default schema is `spec-driven`).

**Step 5. Create artifacts in dependency order**

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

Fill in the template with your analysis from the exploration. Read any existing context files for reference.

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

**Step 6. Show final status**

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

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- Prompt: "Run `/ai-spec-apply $name` to start implementing."

**Guidelines**:
- Fill in templates with real content based on the exploration and codebase analysis
- Read dependency artifacts for context before creating new ones
- If context is critically unclear, ask the user — but prefer making reasonable decisions to keep momentum
- Verify each artifact file exists after writing before proceeding to next

---

## Guardrails

- **Don't implement** — Never write code or implement features. Creating AI artifacts is fine, writing application code is not.
- **Don't fake understanding** — If something is unclear, dig deeper
- **Don't rush** — Discovery is thinking time, not task time
- **Don't force structure** — Let patterns emerge naturally
- **Don't auto-capture** — Offer to save insights, don't just do it
- **Do visualize** — A good diagram is worth many paragraphs
- **Do explore the codebase** — Ground discussions in reality
- **Do question assumptions** — Including the user's and your own

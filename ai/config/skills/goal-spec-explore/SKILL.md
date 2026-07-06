---
name: goal-spec-explore
description: Enter explore mode - think through ideas, investigate problems, clarify requirements
disable-model-invocation: true
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
set -euo pipefail
PROJECT_ROOT="$(pwd)"
while [ "$PROJECT_ROOT" != "/" ] && { [ ! -d "$PROJECT_ROOT/ai" ] || [ ! -d "$PROJECT_ROOT/modules" ]; }; do
  PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
[ "$PROJECT_ROOT" = "/" ] && PROJECT_ROOT="."
cd "$PROJECT_ROOT"
ls -1 "${PROJECT_ROOT}/ai/output/changes/" 2>/dev/null | grep -v '^archive$' || echo "No active changes found"
```

This tells you if there are active changes and their names.

If the user mentioned a specific change name, read its artifacts for context.

---

## When a Change Exists

If the user mentions a change or you detect one is relevant:

1. **Check artifact status**
   ```bash
   change_dir="${PROJECT_ROOT}/ai/output/changes/$name"
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
   | New requirement discovered | `ai/output/specs/<capability>/spec.md` |
   | Requirement changed | `ai/output/specs/<capability>/spec.md` |
   | Design decision made | `ai/output/changes/<name>/design.md` |
   | Scope changed | `ai/output/changes/<name>/proposal.md` |
   | New work identified | `ai/output/changes/<name>/tasks.md` |

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

If the user replies affirmatively — e.g. "创建", "创建变更", "创建变更吧", "创建吧", "好", "yes", "create" — **directly create the change** by delegating to the `goal-spec-propose` skill:

1. Derive a kebab-case change name from the exploration topic (e.g., "add user authentication" → `add-user-auth`).
2. Read and follow `${PROJECT_ROOT}/ai/config/skills/goal-spec-propose/SKILL.md`, passing the derived change name. That skill creates the change directory and generates all artifacts (proposal, specs, design, tasks) in one step. Carry the exploration context into the proposal.

If the user runs `/ai-spec-propose` directly, that command handles the full flow independently.

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

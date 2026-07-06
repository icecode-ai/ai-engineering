---
description: Enter explore mode - think through ideas, investigate problems, clarify requirements
---

Invoke the `goal-spec-explore` skill (a passive, non-auto-triggered skill) to enter explore mode — think through ideas, investigate problems, clarify requirements. When exploration concludes, offer to transition into creating a change.

## 1. Explore

Resolve `PROJECT_ROOT` (the directory containing both `ai/` and `modules/`), then read and follow the skill instructions at:

`${PROJECT_ROOT}/ai/config/skills/goal-spec-explore/SKILL.md`

Pass through the user's arguments: `$ARGUMENTS`

The skill is pure exploration — it does not create any change. You drive the exploration conversation per the skill's stance and guardrails.

## 2. Transition to creating a change

When exploration reaches a natural conclusion (decisions crystallized, user seems ready to move forward), **ask the user whether they want to create a change**. For example:

> "Exploration looks complete. Would you like to create a change proposal from this? Reply to confirm, or run `/ai-spec-propose` directly."

If the user declines or wants to continue exploring, respect that — no pressure.

If the user replies affirmatively — e.g. "创建", "创建变更", "创建变更吧", "创建吧", "好", "yes", "create" — **directly create the change** by delegating to the `goal-spec-propose` skill:

1. Derive a kebab-case change name from the exploration topic (e.g., "add user authentication" → `add-user-auth`).
2. Read and follow `${PROJECT_ROOT}/ai/config/skills/goal-spec-propose/SKILL.md`, passing the derived change name. That skill creates the change directory and generates all artifacts (proposal, specs, design, tasks) in one step. Carry the exploration context into the proposal.

If the user runs `/ai-spec-propose` directly, that command handles the full flow independently.

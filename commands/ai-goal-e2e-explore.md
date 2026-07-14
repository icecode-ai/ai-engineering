---
description: Exploratory end-to-end flow — explore, propose, apply, push, release, test, and archive with user confirmations at key steps
argument-hint: <requirement-description-or-file-or-url>
---

Exploratory end-to-end flow to complete a requirement: explore ideas, create a change, implement it, then — with user confirmations — push to git, release, run regression tests, and archive.

**Input**: One argument — the requirement, in one of three forms:
- A requirement description (text)
- A requirement file path (e.g., `ai/input/jim/0/prd.md`)
- A requirement URL (web link)

## Working directory

Run from the workspace root — the directory containing both `ai/` and `modules/`. All paths below are relative to it.

## Business skill discovery

Several steps reference optional business skills the user may have added under `ai/config/skills/`. Discover them by listing each skill and its description, then match by semantic understanding:

```bash
for d in ai/config/skills/*/; do
  [ -f "${d}SKILL.md" ] || continue
  name="$(basename "$d")"
  desc="$(awk '/^description:/{sub(/^description:[ ]*/,"");print;exit}' "${d}SKILL.md")"
  echo "${name} | ${desc}"
done
```

Match each skill's description semantically to one of the following categories. A skill matches a category if its description indicates it handles that category's concerns — do not rely on exact keyword matches.

- **Infrastructure**: database schema changes, migrations, dynamic configuration, infrastructure provisioning
- **Testing**: regression testing, test execution, test automation
- **Release**: deployment, publishing, release management

If a matching skill is found, read and follow its `SKILL.md`, passing the relevant context. If none is found, skip that step.

## Steps

### 1. Explore (interactive)

Read and follow `ai/config/skills/goal-spec-explore/SKILL.md`, passing the input requirement. This is an open-ended exploration stance — think through the problem, investigate the codebase, clarify requirements with the user. When exploration reaches a natural conclusion (decisions crystallized), synthesize the outcome into a clear **explored requirement** to carry forward.

### 2. Infrastructure changes (if involved) — ask the user

Assess whether the explored requirement involves infrastructure changes (e.g., database schema, dynamic configuration). If it does:

1. Discover an infrastructure skill (see [Business skill discovery](#business-skill-discovery)).
2. If found, **ask the user** whether to add these infrastructure changes to the requirement.
3. If the user confirms, read and follow the infra skill's `SKILL.md`, passing the infrastructure-related changes. Infrastructure skills typically handle multiple environments (test/staging/prod, or daily/pre-release/online): test environments usually allow direct changes; production changes output a **change URL** for the user to execute later. Incorporate the results into the explored requirement.
4. If the user declines, proceed without infrastructure changes.

If no infrastructure skill is found, or the requirement involves no infrastructure changes, skip this step.

### 3. Create the change (propose) — no prompt

Read and follow `ai/config/skills/goal-spec-propose/SKILL.md`, passing the explored requirement. The skill derives a kebab-case change name, creates the change directory, and generates all artifacts (proposal, specs, design, tasks). Record the **change name**. Do not ask the user — create the change directly.

### 4. Implement the change (apply) — no prompt

Read and follow `ai/config/skills/goal-spec-apply/SKILL.md`, passing the change name. The skill implements all tasks via subagent-driven development with two-stage review. Do not ask the user.

### 5. Git push — ask the user

**Ask the user** whether to commit and push to git. If the user confirms, read and follow `ai/config/skills/goal-git-push/SKILL.md`, passing `ALL` as the target. If the user declines, skip.

### 6. Release — ask the user

If the change needs releasing, discover a release skill (see [Business skill discovery](#business-skill-discovery)). If found, **ask the user** whether to release. If the user confirms, read and follow the release skill's `SKILL.md`, passing the change name and context — release typically targets the test environment first. If the user declines, or no release skill is found, skip.

### 7. Regression testing (if a test skill exists)

If the change involves testable behavior, discover a testing skill (see [Business skill discovery](#business-skill-discovery)). If found, read and follow its `SKILL.md`, passing the change name and context — run regression tests (local and/or online, as the skill dictates). Do not ask the user unless the skill requires input. If none is found, skip this step.

### 8. Output the report

Write a report to `ai/output/changes/<change-name>/report.md`:

```markdown
# Report: <change-name>

## Requirement
<original requirement summary>

## Exploration
<explored requirement summary — key decisions, scope>

## Infrastructure Changes
<if any: what changed, environments, change URLs; else "None">

## Change
- **Name:** <change-name>
- **Location:** ai/output/changes/<change-name>/

## Implementation
- **Tasks completed:** N/N
- **Status:** <passed / failed>

## Git
<if pushed: commits, branches; else "Not pushed">

## Release
<if released: environment, version, status; else "Not released">

## Testing
<if run: scope and results; else "Skipped — no test skill">

## Conclusion
<summary>
```

After writing, print the report path to the user.

### 9. Archive — ask the user

**Ask the user** whether to archive the change. If the user confirms, read and follow `ai/config/skills/goal-spec-archive/SKILL.md`, passing the change name. If the user declines, leave the change active.

## Guardrails

- **Two kinds of user interaction**: step 1 (explore) asks open-ended clarifying questions to refine the requirement; confirmation gates (yes/no whether to proceed) occur only at steps 2 (infrastructure), 5 (git push), 6 (release), and 9 (archive). Steps 3, 4, and 7 proceed without asking.
- **Carry context between steps**: the explored requirement flows into propose; the change name flows into apply, push, release, testing, report, and archive.
- **Respect user declines**: if the user declines git push, release, or archive, skip that step and continue.
- **Skip gracefully**: if an optional business skill is not found, skip that step and continue — do not block.

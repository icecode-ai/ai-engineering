---
description: Automated requirement flow — explore, propose, apply, and test without git push/release or user prompts
argument-hint: <requirement-description-or-file-or-url>
---

Automated flow to complete a requirement: explore the requirement, create a change, implement it, and run regression tests — **without git push, release, or asking the user during the process**. Make reasonable decisions autonomously and proceed.

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

### 1. Explore the requirement

Read and follow `ai/config/skills/goal-requirements-explore/SKILL.md`, passing the input requirement. The skill outputs a structured, complete requirement document. Carry this forward as the **explored requirement**.

### 2. Infrastructure changes (if involved)

Assess whether the explored requirement involves infrastructure changes (e.g., database schema, dynamic configuration). If it does:

1. Discover an infrastructure skill (see [Business skill discovery](#business-skill-discovery)).
2. If found, read and follow its `SKILL.md`, passing the infrastructure-related changes. Infrastructure skills typically handle multiple environments (test/staging/prod, or daily/pre-release/online): test environments usually allow direct changes; production changes output a **change URL** for the user to execute later.
3. Incorporate the infrastructure change results into the explored requirement.

If no infrastructure skill is found, or the requirement involves no infrastructure changes, skip this step. Do not ask the user.

### 3. Create the change (propose)

Read and follow `ai/config/skills/goal-spec-propose/SKILL.md`, passing the explored requirement. The skill derives a kebab-case change name, creates the change directory, and generates all artifacts (proposal, specs, design, tasks). Record the **change name** for subsequent steps. Do not ask the user.

### 4. Implement the change (apply)

Read and follow `ai/config/skills/goal-spec-apply/SKILL.md`, passing the change name. The skill implements all tasks via subagent-driven development with two-stage review. Do not ask the user.

### 5. Regression testing (if a test skill exists)

If the change involves testable behavior, discover a testing skill (see [Business skill discovery](#business-skill-discovery)). If found, read and follow its `SKILL.md`, passing the change name and context — run local regression tests. If none is found, skip this step.

### 6. Output the report

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

## Testing
<if run: scope and results; else "Skipped — no test skill">

## Conclusion
<summary>
```

After writing, print the report path to the user.

## Guardrails

- **No git operations**: do not commit or push — implementation files are left on disk for the user to commit later.
- **No release**: do not publish or deploy.
- **No user prompts**: make reasonable decisions autonomously; do not ask the user during the flow.
- **Carry context between steps**: the explored requirement flows into propose; the change name flows into apply, testing, and the report.
- **Skip gracefully**: if an optional business skill is not found, skip that step and continue — do not block.

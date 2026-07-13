---
description: Automated end-to-end flow — explore, propose, apply, push, release, test, and archive without user prompts
argument-hint: <requirement-description-or-file-or-url>
---

Automated end-to-end flow to complete a requirement: explore the requirement, create a change, implement it, push to git, release, run regression tests, and archive — **without asking the user during the process**. Make reasonable decisions autonomously and proceed.

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

Read and follow `ai/config/skills/goal-spec-propose/SKILL.md`, passing the explored requirement. The skill derives a kebab-case change name, creates the change directory, and generates all artifacts (proposal, specs, design, tasks). Record the **change name**. Do not ask the user.

### 4. Implement the change (apply)

Read and follow `ai/config/skills/goal-spec-apply/SKILL.md`, passing the change name. The skill implements all tasks via subagent-driven development with two-stage review. Do not ask the user.

### 5. Git push

Read and follow `ai/config/skills/goal-git-push/SKILL.md`, passing `ALL` as the target. Do not ask the user.

### 6. Release (if a release skill exists)

If the change needs releasing, discover a release skill (see [Business skill discovery](#business-skill-discovery)). If found, read and follow its `SKILL.md`, passing the change name and context — release typically targets the test environment first. If none is found, skip this step. Do not ask the user.

### 7. Regression testing (if a test skill exists)

If the change involves testable behavior, discover a testing skill (see [Business skill discovery](#business-skill-discovery)). If found, read and follow its `SKILL.md`, passing the change name and context — run regression tests (local and/or online, as the skill dictates). If none is found, skip this step. Do not ask the user.

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
<commits, branches>

## Release
<if released: environment, version, status; else "Skipped — no release skill">

## Testing
<if run: scope and results; else "Skipped — no test skill">

## Conclusion
<summary>
```

After writing, print the report path to the user.

### 9. Archive

Read and follow `ai/config/skills/goal-spec-archive/SKILL.md`, passing the change name. Do not ask the user.

## Guardrails

- **No user prompts**: make reasonable decisions autonomously; do not ask the user during the flow.
- **Carry context between steps**: the explored requirement flows into propose; the change name flows into apply, push, release, testing, report, and archive.
- **Skip gracefully**: if an optional business skill is not found, skip that step and continue — do not block.

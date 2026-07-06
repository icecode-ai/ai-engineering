## 背景

帮我看下 `ai/config/skills/goal-spec-explore/SKILL.md` 这个技能，它是基于 `.ai/references/open_spec_commands/opsx-explore.md` 改造，会被 `commands/ai-spec-explore.md` 这个指令调用

## 需求

我还是想保留 `ai/config/skills/goal-spec-explore/SKILL.md` 这个技能的纯粹，创建变更的流程不在这里面，和  `.ai/references/open_spec_commands/opsx-explore.md` 这个一样

创建变更，放在 `commands/ai-spec-explore.md` 这个指令里面

也就是当用户调用 `/ai-spec-explore` 这个指令时，触发以下步骤
1. 调用 `goal-spec-explore` 技能探索需求
2. 当探索完成时，用户 如回复 `创建` 或调用 `/ai-spec-propose` 指令，开始创建变更

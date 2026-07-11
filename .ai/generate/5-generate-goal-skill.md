## 创建 `goal-requirements-explore` 技能

当用户需求不明确或一句话需求，这个技能可以探索需求的意图，实现需求描述的完整性

Explore and complete an unclear or one-line requirement into a full, unambiguous requirement by reading project context

接收 1 个入参数
* 需求：`需求描述` 或 `需求文件` 或 `需求链接地址`

探索需求步骤
1. 可以阅读 `modules/` 下 `需求相关模块` 的 `README.md` 或 `AGENTS.md` 或 `CLAUDE.md`。如果明确了，不再向下进行
2. 可以阅读 `ai/output/specs/` 下的 `需求相关Spec知识`。如果明确了，不再向下进行
3. 可以阅读 `ai/output/memories/` 下的 `需求相关经验`。如果明确了，不再向下进行
4. 可以阅读 `ai/output/changes/archive/` 下的 `需求相关变更记录`。如果明确了，不再向下进行
5. 可以阅读 `modules/` 下 `需求相关模块` 的 `代码` 或 `其他内容`。如果明确了，不再向下进行
6. 可以阅读 `readonly-dependencies/` 下 `需求相关依赖` 的 `代码` 或 `其他内容`。如果明确了，不再向下进行

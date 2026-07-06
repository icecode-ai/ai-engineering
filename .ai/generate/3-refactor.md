# 项目重构

基于 openspec 和 superpowers 的分析，我想重构此项目
* `openspec 与 superpowers 整合需求` 阅读 `.ai/generate/3-sepc.md`
* `openspec 与 superpowers 整合方案` 阅读 `.ai/generate/3-result.md`

## 重构概览

1. 用户安装此项目时，不再安装 `superpowers` 插件，而是实现此插件自闭环，按照 `openspec 与 superpowers 整个方案` 进行实现
2. `commands/` 目录下的指令，里面的内容，改成调用 `ai/config/skills/` 目录下的技能，所以要将 `commands/` 目录下的指令内容抽取到 `ai/config/skills/` 目录下，变成 `非自动调用skill技能`

## 重要提醒
1. `ai/config/skills/` 目录下的技能都是 `非自动调用技能`，不会放在系统提示词的`工具列表中`，只有用户输入中明确指定，才会触发

## 重构需求

### skill 规范

1、新建 skill 都放在 `ai/config/skills/` 目录下 

2、A skill is a directory containing, at minimum, a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code，如 bash 脚本存放
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources，如 markdown 模版、图片、文件 存放
└── ...               # Any additional files or directories
```

3、skill `YAML frontmatter` 规范

```YAML
---
name: <技能名称>
description: <精确描述>
argument-hint: ＜参数提示>（仅需要参数的 skill）
disable-model-invocation: true (设为 true 禁止 Agent 自动触发，仅能手动 /name 调用)
---
```

4、skill 内容规范

The Markdown body after the frontmatter contains the skill instructions. There are no format restrictions. Write whatever helps agents perform the task effectively.

Recommended sections:

* Step-by-step instructions
* Examples of inputs and outputs
* Common edge cases

Note that the agent will load this entire file once it's decided to activate a skill. Consider splitting longer `SKILL.md` content into referenced files.

所有技能，调用的脚本，还是用 `bash` 脚本实现

这里还有一个点，你帮我确认下，例如：如果调用 `bash命令脚本`，路径是否需要以 `ai/config/skills/<skill>/scripts/` 开头，还是直接 `scripts/` 就可以，因为不是 Agent 标准的存放加载路径规范，不确定 AI 是否能找到

### 重构内容明细

#### `commands/` 目录下的 `spec` 相关指令

1、新建 `goal-spec-<xx>` 技能，`commands/` 目录的指令调用这些技能，有参数的直接传递

2、按照 `openspec 与 superpowers 整合方案`，将 `superpowers` 整合进这些技能里面
* 方案中 `进度 ledger：每任务 review 通过后，在同一轮追加一行到 .ai/output/changes/<name>/.sdd/progress.md` 部分，我希望这里进度文件夹改成 `ai/output/changes/<name>/sdd/` 目录，按照我的目录规范来
* `P3 — 按任务复杂度选模型` 这个不用实现
* 由于 `commands/ai-spec-explore.md` 这个指令比较特殊，整合了创建变更的能力，现在拆成 skill 了，可以直接调用 `/goal-spec-propose` 技能进行实现了，但探索完成后，还是要保留，当用户回复如`创建`时，直接创建变更的能力

#### `commands/` 目录下的 `非spec` 相关指令

1、新建 `goal-<xx>` 技能，`commands/` 目录的指令调用这些技能，有参数的直接传递

## 其它要求
* 由于本次重构特别大，内容量多，一定要严谨实现，不能有遗漏或错误
* 接下来，开始设计方案和实现吧
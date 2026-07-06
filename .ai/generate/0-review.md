按以下要求，逐个进行检查，有问题，等我确认后，再修复。过程中如果要向我提问，用 `中文` 向我提问

1. 帮我检查 `commands/` 目录下的指令 `内容描述`、`bash 脚本` 有没有问题，`bash 脚本格式`、`markdown 模版格式` 有没有对齐
2. 帮我检查 `ai/config/skills/` 目录下的技能 `内容描述`、`bash 脚本` 有没有问题，`bash 脚本格式`、`markdown 模版格式` 有没有对齐


## 其他规范参考

### command 规范

command 文件在 `commands/` 目录，带 `.md` 及 `YAML frontmatter`

```YAML
---
description: <精确描述>
argument-hint: ＜参数提示>（仅需要参数的 command）
---
```

### skill 规范

1、非自动调用 skill 在 `ai/config/skills/` 目录下

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
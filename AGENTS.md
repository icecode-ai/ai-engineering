这是一个插件项目，会被用户安装到各种 Agent 中，比如 `Claude Code`、`OpenCode`、`Qoder` 等

安装方式阅读 `README.md` 文件

用户安装后，以下内容会缓存在Agent指定缓存路径，但是作用域是`项目`级别，内容包括：
1. `commands/` 目录下的指令
2. `skills/` 目录下的技能
3. `agents/` 目录下的 `自定义SubAgent`

以下内容 当用户执行 `/ai-env-init` 指令后，会同步拷贝到 `用户的项目路径`
* `ai/` 目录下的内容，拷贝到 `用户项目` 的 `ai/` 目录

本项目 2 个 `skills` 目录的区别
* `skills/` 目录下存放 `自动触发的技能`，Agent 会默认加载
* `ai/config/skills/` 目录下存放 `被动触发的技能`，只有用户明确指定调用时，才会触发
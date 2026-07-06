帮我看下这个技能 `ai/config/skills/goal-env-init/SKILL.md`

这个技能会被 `commands/ai-env-init.md` 指令调用

但是，有个问题，`commands/` 是在插件安装目录，`ai/` 会拷贝到 `用户项目 ai/` 目录

所以 SKILL 中 `PLUGIN_ROOT`，能找到吗，是否需要 `接收参数`，由 command 传递进来

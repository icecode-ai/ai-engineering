帮我生成这个插件项目的门户网页，只用生成一个 `index.html`

## 要求

1. 顶部固定菜单导航栏
2. 导航栏左侧 logo `AI Engineering`
3. 导航栏包含菜单 `概览`、`安装`、`项目结构`、`核心流程`、`核心命令`
4. `概览` 模块：一行 `AI Engineering` 字大一点，一行 `项目概述`，一行 `tag` 本项目核心亮点
5. `安装` 模块：安装方式，用户agent内，告诉 agent `Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_{xxx}.md` , 支持 `INSTALL_4_CLAUDE.md`、`INSTALL_4_OPENCODE.md`、`INSTALL_4_QODER.md`
6. `项目结构` 模块，用户执行完 `/ai-env-init` 之后，生成的项目结构，参考 `README.md`
7. `核心命令` 模块，参考 `.ai/generate_commands.md` 中的几大类
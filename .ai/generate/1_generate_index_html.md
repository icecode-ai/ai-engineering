帮我生成这个插件项目的门户网页，只用生成一个 `index.html`

## 要求

1. 顶部固定菜单导航栏
2. 导航栏左侧 logo `AI Engineering`
3. 导航栏包含菜单 `概览`、`安装`、`工程结构`、`流程`、`命令`
4. `概览` 模块：一行 `AI Engineering` 字大一点，一行 `项目概述`，一行 `tag` 本项目核心亮点
5. `安装` 模块：安装方式，用户agent内，告诉 agent `Fetch and follow instructions from https://raw.githubusercontent.com/icecode-ai/ai-engineering/refs/heads/main/INSTALL_4_{xxx}.md` , 支持 `INSTALL_4_CLAUDE.md`、`INSTALL_4_OPENCODE.md`、`INSTALL_4_QODER.md`
6. `工程结构` 模块，用户执行完 `/ai-env-init` 之后，生成的项目结构，参考 `README.md`
7. `流程` 模块：展示增强 OpenSpec 工作流的四步 `explore → propose → apply → archive`，并配一个终端示例对话框，完整对话内容固定为以下 5 行：
   - `USER> /ai-spec-explore @ai/archetypes/tom/0/prd.md`
   - `AI> 已进入探索模式，正在分析 PRD 并梳理需求...`
   - `USER> 创建变更 或 /ai-spec-propose`
   - `AI> 创建变更中..`
   - `USER> /ai-spec-apply`
8. `命令` 模块，参考 `.ai/generate_commands.md` 中的几大类
9. 中英文双语支持：右上角语言切换按钮，默认英文；所有文案通过 `data-i18n`/`data-i18n-html` 属性绑定，提供完整中英文翻译，切换实时生效并用 `localStorage` 记忆语言偏好
10. 生成完成后，基于最新的 `index.html` 内容同步更新 `README.md`

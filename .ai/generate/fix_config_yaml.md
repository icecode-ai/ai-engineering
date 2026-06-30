`openspec` 在 init 用户项目的时候，生成了 `config.yaml` (参考 `/Users/doer/Documents/code/ai/ai-engineering-test/openspec/config.yaml`)

它是如何应用的

`openspec` 开源库: https://github.com/Fission-AI/OpenSpec.git ，下载来阅读参考下

背景：

我这个项目基于OpenSpec做了改造，是一个插件，可以被用户安装，可以阅读 `index.html` 看下

需求：
我这个项目
* 当用户执行 `commands/ai-env-init.md` 指令的时候，是不是也要生成 `config.yaml`，写入到 `ai/` 目录下
* 当用户执行 `commands/ai-spec-xx.md` 指令的时候，如何像原生 `openspec` 一样，应用 `config.yaml`

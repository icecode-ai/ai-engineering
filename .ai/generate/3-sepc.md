`commands/` 目录下的 `spec` 相关指令是基于 `openspec` 改造的

1. 下载 `openspec 源码` `https://github.com/Fission-AI/OpenSpec.git` 到缓存目录
2. 下载 `superpowers 插件源码` `https://github.com/obra/superpowers.git` 到缓存目录
3. 阅读 `.ai/references/openspec_superpowers.html` 看下 `openspec` 和 `superpowers` 结合的方式
4. 看下 `openspec` 和 `superpowers` 在 `探索任务`、`拆分任务`、`执行任务` 等层面有什么差异，包括执行任务调用层面是`并行`还是`串行` (case: SubAgent 调用)，看下这两个插件，在这几个维度对比，哪个更优，以及 `commands/` 目录下的 `spec` 相关指令是否可以优化

分析对比结果写入到 `.ai/generate/3-result.md` 文件中
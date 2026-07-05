需求，帮我检查和优化 `commands/` 目录下的指令

## ai-dependency-add.md

1、如果 `添加依赖失败`，还会生成 `主项目指导文件` 吗？我希望`添加失败时`，`不再生成`

2、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-dependency-remove

1、如果 `添加依赖失败`，还会生成 `主项目指导文件` 吗？我希望`删除失败时`，`不再生成`

2、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-env-init

1、第 1 步 bash 脚本中，去掉生成 `/ai/config/spec-config.yaml` 文件部分

2、生成 `子模块指导文件` 调整
* 如果 `CLAUDE.md` 和 `AGNETS.md` 都不存在，则双写生成 `CLAUDE.md` 和 `AGNETS.md`，生成采用 `Other agents` 中的方式，不再用 Claude 的 `/init` skill
* 如果 `子模块` 中存在 `CLAUDE.md` 并且不存在 `AGNETS.md`，则拷贝 `CLAUDE.md` 到 `AGNETS.md`
* 如果 `子模块` 中存在 `AGNETS.md` 并且不存在 `CLAUDE.md`，则拷贝 `AGNETS.md` 到 `CLAUDE.md`

3、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-git-checkout

1、如果 `checkout失败或无更新时`，还会生成 `对应的指导文件` 吗？我希望`checkout失败或无更新时`，`不再生成`

2、生成 `子模块指导文件` 调整
* 如果 `CLAUDE.md` 和 `AGNETS.md` 都不存在，则双写生成 `CLAUDE.md` 和 `AGNETS.md`，生成采用 `Other agents` 中的方式，不再用 Claude 的 `/init` skill
* 如果 `子模块` 中存在 `CLAUDE.md` 并且不存在 `AGNETS.md`，则拷贝 `CLAUDE.md` 到 `AGNETS.md`
* 如果 `子模块` 中存在 `AGNETS.md` 并且不存在 `CLAUDE.md`，则拷贝 `AGNETS.md` 到 `CLAUDE.md`

3、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-git-merge

1、如果 `merge失败或无更新时`，还会生成 `对应的指导文件` 吗？我希望`merge失败或无更新时`，`不再生成`

2、生成 `子模块指导文件` 调整
* 如果 `CLAUDE.md` 和 `AGNETS.md` 都不存在，则双写生成 `CLAUDE.md` 和 `AGNETS.md`，生成采用 `Other agents` 中的方式，不再用 Claude 的 `/init` skill
* 如果 `子模块` 中存在 `CLAUDE.md` 并且不存在 `AGNETS.md`，则拷贝 `CLAUDE.md` 到 `AGNETS.md`
* 如果 `子模块` 中存在 `AGNETS.md` 并且不存在 `CLAUDE.md`，则拷贝 `AGNETS.md` 到 `CLAUDE.md`

3、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-git-pull

1、如果 `pull失败或无更新时`，还会生成 `对应的指导文件` 吗？我希望`pull失败或无更新时`，`不再生成`

2、生成 `子模块指导文件` 调整
* 如果 `CLAUDE.md` 和 `AGNETS.md` 都不存在，则双写生成 `CLAUDE.md` 和 `AGNETS.md`，生成采用 `Other agents` 中的方式，不再用 Claude 的 `/init` skill
* 如果 `子模块` 中存在 `CLAUDE.md` 并且不存在 `AGNETS.md`，则拷贝 `CLAUDE.md` 到 `AGNETS.md`
* 如果 `子模块` 中存在 `AGNETS.md` 并且不存在 `CLAUDE.md`，则拷贝 `AGNETS.md` 到 `CLAUDE.md`

3、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-module-add

1、如果 `添加模块失败时`，还会生成 `对应的指导文件` 吗？我希望`添加模块失败时`，`不再生成`

2、生成 `子模块指导文件` 调整
* 如果 `CLAUDE.md` 和 `AGNETS.md` 都不存在，则双写生成 `CLAUDE.md` 和 `AGNETS.md`，生成采用 `Other agents` 中的方式，不再用 Claude 的 `/init` skill
* 如果 `子模块` 中存在 `CLAUDE.md` 并且不存在 `AGNETS.md`，则拷贝 `CLAUDE.md` 到 `AGNETS.md`
* 如果 `子模块` 中存在 `AGNETS.md` 并且不存在 `CLAUDE.md`，则拷贝 `AGNETS.md` 到 `CLAUDE.md`

3、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`

## ai-module-remove

1、如果 `删除模块失败时`，还会生成 `对应的指导文件` 吗？我希望`删除模块失败时`，`不再生成`

2、生成 `主项目指导文件` 调整
* 不再根据用户用的 `Agent` 判断生成 `CLAUDE.md` 或是 `AGNETS.md`，换成采用双写的形式，同步创建和更新 `AGENTS.md` 和 `CLAUDE.md`
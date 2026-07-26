# 领域模型架构开发规范

领域模型架构（DDD）= 严格分层 + 富领域模型 + 端口适配器（依赖倒置）。业务逻辑内聚在聚合根，领域层通过端口接口声明对外依赖，基础设施层提供实现

## Maven 多模块分层规范

| 层 | 描述 | 规范文件 |
|---|---|---|
| domain 领域层 | 聚合根/值对象/领域服务/领域事件/Repository 接口，业务逻辑内聚 | `ai/config/rules/java/ddd/java-ddd-domain-guidelines.md` |
| application 应用编排层 | 领域编排，无业务逻辑 | `ai/config/rules/java/ddd/java-ddd-application-guidelines.md` |
| interface 接口层 | Web接口/RPC服务/MQ监听/定时任务等 | `ai/config/rules/java/ddd/java-ddd-interface-guidelines.md` |
| client 开放层 | 对外发布 API jar（接口 + DTO），无 Lombok，供外部消费 | `ai/config/rules/java/ddd/java-ddd-client-guidelines.md` |
| infrastructure 基础设施层 | Repository 实现/Dao/DO/Converter/多数据源 | `ai/config/rules/java/ddd/java-ddd-infrastructure-guidelines.md` |
| facade 防腐层 | 二/三方服务隔离，返回 DTO，可移植 | `ai/config/rules/java/ddd/java-ddd-facade-guidelines.md` |
| starter 启动层 | Application 主类、多环境配置、测试 | `ai/config/rules/java/ddd/java-ddd-starter-guidelines.md` |

## Maven 多模块核心逻辑关系

- `starter 启动层` 控制整个应用的启动，仅包含 启动类、应用配置、单测
- `interface 接口层` > `application 应用编排层` > `domain 领域层`
- `infrastructure 基础设施层` > `facade 防腐层`

## 其他规范

- 【推荐】校验逻辑，尽量使用 `Assert` 校验，比如：`Assert.isTrue`，减少 if 判断

- 【强制】业务逻辑内聚在`domain 领域层`；优先思考 `domain 领域层` 的设计，因为是 DDD 领域模型驱动开发，向外延伸到需要哪些依赖，以及 `application 应用编排层` 如何编排领域流程；`domain 领域层` 不感知 DB/MQ/三方服务，仅声明接口；基础设施层提供实现

- 【强制】二/三方服务依赖，比如依赖的 RPC、HTTP 服务等，统一放在 `facade 防腐层`，在 `facade 防腐层` 中定义依赖和版本号
- 【强制】如果用户需求中，没有明确说明需要开放接口，不要在 `client 开放层` 定义接口，接口放在 `interface 接口层`，`interface 接口层` 需要的出入参 `Query`、`Command`、`DTO` 放在 `application 应用编排层`
- 【强制】所有单测放在 `starter 启动层`

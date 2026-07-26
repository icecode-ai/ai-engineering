# 中台架构开发规范

中台架构 = DDD 富领域模型 + 扩展点（SPI）机制。通过 `extension`（扩展点定义）+ `extension-apps`（业务变体插件）实现「对扩展开放、对修改关闭」，支持多业务线（多租户）的业务变体插件化（如不同平台订单属性差异）

## Maven 多模块分层规范

| 层 | 描述 | 规范文件 |
|---|---|---|
| domain 领域层 | 聚合根/值对象/领域服务/领域事件/Repository 接口/动态配置(KV、开关等)，业务逻辑内聚，调用扩展点路由业务变体 | `ai/config/rules/java/bmp/java-bmp-domain-guidelines.md` |
| extension 扩展点定义层 | 扩展点 SPI 定义 + 默认空白实现 | `ai/config/rules/java/bmp/java-bmp-extension-guidelines.md` |
| extension-apps 扩展实现层 | 按 bizCode 实现扩展点的业务变体插件 | `ai/config/rules/java/bmp/java-bmp-extension-apps-guidelines.md` |
| application 应用编排层 | 领域编排，无业务逻辑 | `ai/config/rules/java/bmp/java-bmp-application-guidelines.md` |
| interface 接口层 | Web接口/RPC服务/MQ监听/定时任务等 | `ai/config/rules/java/bmp/java-bmp-interface-guidelines.md` |
| client 开放层 | 对外发布 API jar（接口 + DTO），无 Lombok，供外部消费 | `ai/config/rules/java/bmp/java-bmp-client-guidelines.md` |
| infrastructure 基础设施层 | Repository 实现/Dao/DO/Converter/多数据源/缓存 | `ai/config/rules/java/bmp/java-bmp-infrastructure-guidelines.md` |
| facade 防腐层 | 二/三方服务隔离，返回 DTO，可移植 | `ai/config/rules/java/bmp/java-bmp-facade-guidelines.md` |
| starter 启动层 | Application 主类、多环境配置、测试 | `ai/config/rules/java/bmp/java-bmp-starter-guidelines.md` |

## Maven 多模块核心逻辑关系

- `starter 启动层` 控制整个应用的启动，仅包含 启动类、应用配置、测试
- `interface 接口层` > `application 应用编排层` > `domain 领域层` > `extension 扩展点定义层`
- `infrastructure 基础设施层` > `facade 防腐层`

## 其他规范

- 【推荐】校验逻辑，尽量使用 `Assert` 校验，比如：`Assert.isTrue`，减少 if 判断

- 【强制】业务逻辑内聚在`domain 领域层`；优先思考 `domain 领域层` 的设计，因为是 DDD 领域模型驱动开发，向外延伸到需要哪些依赖，以及 `application 应用编排层` 如何编排领域流程；`domain 领域层` 不感知 DB/MQ/三方服务，仅声明接口；基础设施层提供实现。扩展点机制使核心领域对业务变体开放扩展、关闭修改

- 【推荐】考虑中台通用能力沉淀，没有业务扩展定制时，也能实现默认业务逻辑的闭环。如果是业务专属逻辑，考虑定制扩展点，但是定制扩展点时，要考虑扩展点的通用性，未来其他业务也可以通过此扩展点定制，也就是扩展点的粒度不要特别细，避免扩展点泛滥

- 【强制】二/三方服务依赖，比如依赖的 RPC、HTTP 服务等，统一放在 `facade 防腐层`，在 `facade 防腐层` 中定义依赖和版本号
- 【强制】如果用户需求中，没有明确说明需要开放接口，不要在 `client 开放层` 定义接口，接口放在 `interface 接口层`，`interface 接口层` 需要的出入参 `Query`、`Command`、`DTO` 放在 `application 应用编排层`
- 【强制】所有测试放在 `starter 启动层`

## Assert 使用规范

- 【推荐】使用 `Assert` 时，必须构造有含义的错误码，全部大写，下划线分割，模版 `{BIZ}_{METHOD}_{PARAM}_{ERROR}`

示例：
```java
public static List<UserDTO> query() {
    // ...
    Assert.notNull(userId, "USER_SERVICE_QUERY_USER_ID_NULL", "用户服务查询用户时用户ID为空");
    // ...
    Assert.notNull(data, "USER_SERVICE_QUERY_DATA_NULL", json.toString());
    // ...
}
```

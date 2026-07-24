# 业务中台架构开发规范

业务中台架构 = DDD 富领域模型 + 扩展点（SPI）机制。通过 `extension`（扩展点定义）+ `extension-apps`（业务变体插件）实现「对扩展开放、对修改关闭」，支持多业务线（多租户）的业务变体插件化（如不同平台订单属性差异）。

## 分层规范

| 层 | 描述 | 规范文件 |
|---|---|---|
| client 开放层 | 对外发布 API jar（接口 + DTO），无 Lombok，供外部消费 | `ai/config/rules/java/b-java-bmp-client-guidelines.md` |
| extension 扩展点定义层 | 扩展点 SPI 定义 + 默认空白实现 | `ai/config/rules/java/c-java-bmp-extension-guidelines.md` |
| domain 领域层 | 聚合根/值对象/领域服务/领域事件/Repository 端口，业务逻辑内聚，调用扩展点路由业务变体 | `ai/config/rules/java/d-java-bmp-domain-guidelines.md` |
| facade 防腐层 | 二/三方服务隔离，返回 DTO，可移植 | `ai/config/rules/java/e-java-bmp-facade-guidelines.md` |
| application 应用编排层 | Module 编排，DTO↔Domain 转换，无业务逻辑，返回 DTO 不包装 Result | `ai/config/rules/java/f-java-bmp-application-guidelines.md` |
| infrastructure 基础设施层 | Repository 实现/DAO/DO/Converter/多数据源，可调用 facade | `ai/config/rules/java/g-java-bmp-infrastructure-guidelines.md` |
| interface 接口层 | Controller/MQ监听/定时任务/OpenServiceImpl，返回 Result 包装 | `ai/config/rules/java/h-java-bmp-interface-guidelines.md` |
| extension-apps 扩展实现层 | 按 bizCode 实现扩展点的业务变体插件 | `ai/config/rules/java/i-java-bmp-extension-apps-guidelines.md` |
| starter 启动层 | Application 主类、多环境配置、测试、代码生成器 | `ai/config/rules/java/j-java-bmp-starter-guidelines.md` |

## 逻辑关系

### 编译期依赖方向（Maven 模块强制，单向）

```
client / extension / facade   （基础模块，互不依赖）
        ▲            ▲
        │            │
   domain ──► extension
        ▲
        │
   application ──► client
        ▲
        │
   infrastructure ──► domain, facade
        ▲
        │
   interface ──► application, facade
        ▲
        │
   extension-apps ──► extension
        ▲
        │
   starter ──► interface, infrastructure, extension-apps
```

- 【强制】domain 与 application 禁止依赖 facade。
- 【强制】client 禁止引入 Lombok 或新增依赖（不污染消费方环境）。

### 运行时调用链（创建订单为例）

```
interface: Controller.create(@Valid Command)
  → application: Module.create(command)
      Assembler.from(command) → 领域聚合根
      聚合根.create(repository, producer)        ← domain 业务逻辑内聚
         ExtensionExecutor.executeFirstNotNull(ExtPt, ...)  ← 路由业务变体
         repository.save(聚合根)                  ← 端口
         producer.send(Message)                   ← 端口
         EventBus.dispatchAsync(Event)            ← 跨域异步事件
      Assembler.to(聚合根) → DTO
  ← 返回 DTO（Module 不包装 Result，Result 仅在 interface 层）
      ↓ 异步事件
application: @EventHandler Module.handler(Event) → 跨域编排（如库存扣减）
infrastructure: RepositoryImpl.save
   Converter.to(聚合根) → DO
   Dao.insertSelective(DO)
   Facade.syncXXX(...)                          ← ACL 三方同步
```

### 端口-适配器（依赖倒置）

| 端口（接口，定义在 domain/extension/client） | 适配器（实现，在 infrastructure/extension-apps/interface） |
|---|---|
| `{Name}Repository extends Repository<E,ID>`（domain） | `{Name}RepositoryImpl @Component`（infrastructure） |
| `{Name}MessageProducer`（domain） | `{Name}MessageProducerImpl @Component`（infrastructure） |
| `{Name}ExtPt extends ExtensionPoint`（extension） | `Blank{Name}Ext`（默认）+ `{bizCode}{Name}Ext @Extension`（extension-apps） |
| `{Name}OpenService`（client） | `{Name}OpenServiceImpl`（interface） |

领域层不感知 DB/MQ/三方服务，仅声明端口；基础设施层提供实现。扩展点机制使核心领域对业务变体开放扩展、关闭修改。

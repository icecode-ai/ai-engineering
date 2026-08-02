# 微服务 - facade 防腐层规范

## 职责
防腐层(ACL)：隔离二/三方服务依赖。封装外部 HTTP/RPC 调用，将外部 DTO 转换为内部 DTO。无业务逻辑、可移植、可被其他项目直接拷贝复用。所有二/三方库依赖只在本层引入，不污染根 POM 与架构

## 包结构
| 包路径 | 说明 |
|---|---|
| `{package}.{partner}.facade` | {Name}Facade @Component |
| `{package}.{partner}.assembler` | {Name}Assembler(MapStruct，外部 DTO ↔ 内部 DTO) |
| `{package}.{partner}.dto` | 外部 DTO({Name}DTO / {Name}Query / {Name}Command / ResultDTO / PageResponseDTO 等) |
| `{package}.{partner}.types` | 值对象(外部DTO子属性 / 枚举 等) |
| `{package}.{partner}.config` | {Name}Configuration @Configuration |

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 防腐服务 | `{Name}Facade @Component` | `PartnerFacade`/`DoubleColorBallFacade` |
| 转换器 | `{Name}Assembler @Mapper` | `PartnerAssembler` |
| 外部 DTO | `{Name}DTO`/`{Name}Query`/`{Name}Command`/`ResultDTO`/`PageResponseDTO` | `DoubleColorBallDTO` |
| 配置 | `{Name}Configuration @Configuration` | `LotteryConfiguration` |

## 规则
- 【强制】不包含业务逻辑，仅做协议转换与数据装配
- 【强制】方法直接返回 DTO/基本类型/Optional，不包装 `Result`/`SingleResponse`
- 【强制】二/三方库依赖只能在本模块 POM 引入，根 POM 不得出现
- 【强制】本层可被其他项目拷贝直接使用，禁止依赖业务模块
- 【推荐】转换逻辑用 MapStruct `@Mapper`，`INSTANCE = Mappers.getMapper(...)`
- 【强制】{Name}Facade 内不使用私有静态方法组装参数，方法内流程编排禁止一堆setter属性值的逻辑，统一用 Assembler，保证流程清晰
- 【建议】出入参，不建议直接使用二、三方依赖中的参数，复杂入参建议用 `Query`、`Command` 包装，出参统一用 `DTO` 包装

## 示例
```java
@Component
public class AiFacade {

    @Resource
    private ChatClient deepseekChatClient;

    @Resource
    private ChatClient qwenChatClient;

    public AiChatDTO deepseek(AiChatQuery query) {
        String content = deepseekChatClient.prompt()
            .system(query.getSystemPrompt())
            .user(query.getUserPrompt())
            .tools(query.getTools())
            .stream().content().collectList()
            .map(list -> String.join("", list))
            .block();
        
        return AiAssembler.INSTANCE.to(content);
    }

    public AiChatDTO qwen(AiChatQuery query) {
        String content = qwenChatClient.prompt()
            .system(query.getSystemPrompt())
            .user(query.getUserPrompt())
            .tools(query.getTools())
            .stream().content().collectList()
            .map(list -> String.join("", list))
            .block();
        
        return AiAssembler.INSTANCE.to(content);
    }
}
```

# 微服务 - facade 防腐层规范

## 职责
防腐层（ACL）：隔离二/三方服务依赖。封装外部 HTTP/RPC 调用，将外部 DTO 转换为内部 DTO。无业务逻辑、可移植、可被其他项目直接拷贝复用。所有二/三方库依赖只在本层引入，不污染根 POM 与架构。

## 包结构
```
{package}.{partner}.
  facade       {Name}Facade @Component
  assembler    {Name}Assembler（MapStruct，外部 DTO ↔ 内部 DTO）
  dto          外部 DTO（{Name}DTO / ResultDTO / PageResponseDTO 等）
  config       {Name}Configuration @Configuration
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 防腐服务 | `{Name}Facade @Component` | `PartnerFacade`/`DoubleColorBallFacade` |
| 转换器 | `{Name}Assembler @Mapper` | `PartnerAssembler` |
| 外部 DTO | `{Name}DTO`/`ResultDTO`/`PageResponseDTO` | `DoubleColorBallDTO` |
| 配置 | `{Name}Configuration @Configuration` | `LotteryConfiguration` |

## 规则
- 【强制】不包含业务逻辑，仅做协议转换与数据装配。
- 【强制】方法直接返回 DTO，不包装 `Result`/`SingleResponse`。
- 【强制】二/三方库依赖只能在本模块 POM 引入，根 POM 不得出现。
- 【强制】弱依赖（外部不可靠调用）须 try-catch 并转 `SysException`，不向上抛原始异常。
- 【强制】本层可被其他项目拷贝直接使用，禁止依赖业务模块。
- 【推荐】转换逻辑用 MapStruct `@Mapper`，`INSTANCE = Mappers.getMapper(...)`。

## 依赖
- 可依赖：`clean-spring-common-starter`、`clean-spring-exception-starter`、`clean-spring-log-starter`、`clean-spring-utils-starter`、Lombok、MapStruct、二/三方库
- 禁止：application、infrastructure、interface、client

## 示例
```java
@Component
public class DoubleColorBallFacade {
    public PageResponse<DoubleColorBallDTO> request(int page) {
        try {
            String resp = Requests.get(URL).body(...).send().readToText();
            ResultDTO<PageResponseDTO<DoubleColorBallDTO>> r = JSON.parseObject(resp, type);
            return DoubleColorBallAssembler.INSTANCE.to(r.getData());
        } catch (Throwable t) {
            throw new SysException("双色球服务调用失败", t);
        }
    }
}
```

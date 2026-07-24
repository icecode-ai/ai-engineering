# 业务中台 - client 开放层规范

## 职责
对外发布的 API jar：开放服务接口 + DTO。供外部消费方（其他应用/微服务）依赖调用，可经 Dubbo 等 RPC 暴露。

## 包结构
```
{package}.{biz}.
  service    开放服务接口 {Name}OpenService
  dto        开放 DTO（{Name}DTO / {Name}Query）
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 开放服务接口 | `{Name}OpenService` | `InventoryOpenService` |
| 开放 DTO | `{Name}DTO extends DTO` | `InventoryDTO` |
| 开放查询 | `{Name}Query extends Query` | `InventoryQuery` |

## 规则
- 【强制】禁止引入 Lombok（不污染消费方 classpath），getter/setter 手写。
- 【强制】依赖最小化，仅依赖 `clean-component-common`，禁止新增二/三方依赖。
- 【强制】发布 sources jar（`maven-source-plugin`），便于消费方查看。
- 【强制】接口方法返回 `SingleResponse`/`PageResponse`。
- 【强制】独立版本号管理，向后兼容；接口签名变更须 `@Deprecated` 渐进。
- 【推荐】DTO 字段用包装类型。

## 依赖
- 可依赖：`clean-component-common`
- 禁止：Lombok、业务模块、二/三方库

## 示例
```java
public interface InventoryOpenService {
    SingleResponse<InventoryDTO> query(InventoryQuery query);
}
```

# 微服务 - interface 接口层规范

## 职责
入站适配器：REST Controller、RPC/Dubbo 服务实现、MQ 监听、定时任务、Web 过滤器。仅做传输协议与应用 `Module` 之间的翻译，无业务逻辑。`Result` 包装（`SingleResponse`/`PageResponse`）仅在本层产生。

## 包结构
```
{package}.{biz}.
  web          {Name}Controller @RestController
  service      {Name}OpenServiceImpl（implements client {Name}OpenService）
  messaging    {Name}MessageListener
  task         {Name}Job
common.web.filter   Web 过滤器
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| REST 控制器 | `{Name}Controller @RestController @RequestMapping("/{biz}")` | `OrderController` |
| 开放服务实现 | `{Name}OpenServiceImpl`（@DubboService 可选） | `InventoryOpenServiceImpl` |
| MQ 监听 | `{Name}MessageListener` | `OrderMessageListener` |
| 定时任务 | `{Name}Job` | `OrderJob` |

## 规则
- 【强制】无业务逻辑，仅调用 application `Module` 并包装结果。
- 【强制】`Result` 包装（`SingleResponse`/`PageResponse`）只在本层返回，application 返回裸 DTO。
- 【强制】异常走拦截器统一拦截，不 try-catch（弱依赖除外）。
- 【强制】入参用 `@Valid` 触发校验，Command/Query 校验注解（`@Min`/`@Max`/`@Pattern`）。
- 【强制】RPC 暴露实现 client 的 `{Name}OpenService` 接口，签名与 client 一致。
- 【推荐】Controller `@RequestMapping("/{biz}")` 统一路径前缀。

## 依赖
- 可依赖：`application`、`facade`、`client`、`spring-boot-starter-web`、validation
- 禁止：`infrastructure`（须通过 application 间接调用）

## 示例
```java
@RestController
@RequestMapping("/order")
public class OrderController {
    @Resource private OrderModule orderModule;

    @PostMapping("/create")
    public SingleResponse<OrderDTO> create(@Valid @RequestBody OrderCreateCommand command) {
        return SingleResponse.of(orderModule.create(command));
    }
}
```

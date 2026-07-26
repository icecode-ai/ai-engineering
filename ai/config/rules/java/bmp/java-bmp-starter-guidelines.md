# 中台架构 - starter 启动层规范

## 职责
启动与装配：`Application` 主类、多环境配置（`application*.properties`/`logback-spring.xml`）、集成测试基类

## 包结构
| 路径 | 说明 |
|---|---|
| `{package}.Application` | @SpringBootApplication 主类 |
| `{package}.(test).BaseTest` | @SpringBootTest 基类 |
| `{package}.(test).TestApplication` | @ActiveProfiles("testing") 测试启动 |
| `{package}.(test).{biz}.{*}.{Name}Test` | 测试 |
| `src/main/resources/application*.properties` | 应用配置（application.properties / application-{env}.properties） |
| `src/main/resources/logback-spring.xml` | 日志配置 |

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 测试类 | `{Name}Test` | `OrderModuleTest` |

## 规则
- 【参考】本地无法启动时，使用 Mock 测试，不继承 BaseTest

## 单测示例
```java
class OrderModuleTest extends BaseTest {

    @Resource
    private InventoryModule inventoryModule;

    @Resource
    private OrderModule orderModule;

    @Test
    void create() {
        long itemId = 123L;

        InventorySaveCommand inventorySaveCommand = new InventorySaveCommand();
        inventorySaveCommand.setItemId(itemId);
        inventorySaveCommand.setAvailableStock(999);

        inventoryModule.save(inventorySaveCommand);

        OrderCreateCommand orderCreateCommand = new OrderCreateCommand();
        orderCreateCommand.setUserId("张三");
        orderCreateCommand.setItemId(itemId);

        OrderDTO orderDTO = orderModule.create(orderCreateCommand);

        assert orderDTO != null;
    }
}
```

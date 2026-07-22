# 业务中台 - extension 扩展点定义层规范

## 职责
定义扩展点 SPI（`ExtensionPoint`）及扩展入参对象（`Input`/`BO`），并提供默认空白实现（`Blank*Ext`）。是 domain 与 extension-apps 之间的契约层，使核心领域可被业务变体插件扩展而无需修改。

## 包结构
```
{package}.
  common         UseCase / Scenario 枚举、BaseInput 基类
  {biz}.
    extension    扩展点接口 {Name}ExtPt extends ExtensionPoint
    bo           扩展入参 {Name}{Action}Input extends BaseInput
    blank        默认空白实现 Blank{Name}Ext @Extension
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 扩展点接口 | `{Name}ExtPt extends ExtensionPoint` | `OrderExtPt` |
| 扩展入参（BO） | `{Name}{Action}Input extends BaseInput` | `OrderCreateInput` |
| 默认空白实现 | `Blank{Name}Ext @Extension` | `BlankOrderExt` |

## 规则
- 【强制】扩展点接口必须 `extends ExtensionPoint`，方法返回值用于 `ExtensionExecutor.executeFirstNotNull` 时须为非 void。
- 【强制】扩展入参须 `extends BaseInput`，携带 bizCode 解析所需上下文。
- 【强制】必须提供 `Blank*Ext` 默认实现并 `@Extension`，保证无匹配 bizCode 时有空实现兜底。
- 【强制】本层不依赖 domain/application/infrastructure，仅作为契约；保持轻量。
- 【推荐】一个业务变体维度对应一个扩展点；扩展点方法粒度聚焦单一职责。

## 依赖
- 可依赖：`clean-spring-extension-starter`、`clean-component-common`
- 禁止：domain、application、infrastructure、interface、facade

## 示例
```java
public interface OrderExtPt extends ExtensionPoint {
    Map<String, Object> createAttributes(OrderCreateInput input);
}

@Extension
public class BlankOrderExt implements OrderExtPt {
    public Map<String, Object> createAttributes(OrderCreateInput input) {
        return Collections.emptyMap();
    }
}
```

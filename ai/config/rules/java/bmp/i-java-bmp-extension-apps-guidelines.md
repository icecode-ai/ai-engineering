# 业务中台 - extension-apps 扩展实现层规范

## 职责
业务变体插件：按 bizCode 实现各扩展点 `{Name}ExtPt`。每个业务线（如淘宝/京东）一个独立 app 子模块，声明 `App`（bizCode 解析器）与 `{Name}Ext`（扩展实现）。是「对扩展开放」的落地层。

## 包结构
```
{package}.app.{bizline}.
  {Name}Ext        @Extension(bizCode=...) implements {Name}ExtPt
  App              @AutoService(App.class)  bizCode 解析器
  common.Constants BIZ_CODE 常量
```
每个业务线一个 Maven 子模块（如 `{artifactId}-taobao-app`、`{artifactId}-jingdong-app`）。

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| bizCode 解析器 | `{BizLine}App @AutoService(App.class)` | `TaoBaoApp`/`JingDongApp` |
| 扩展实现 | `{Name}Ext @Extension(bizCode=...)` | `OrderExt` |
| 常量 | `Constants.BIZ_CODE` | `"tao.bao"`/`"jing.dong"` |

## 规则
- 【强制】每个 app 子模块实现一个业务线的全部扩展点；bizCode 在 `Constants` 中定义为常量。
- 【强制】`App` 须 `@AutoService(App.class)`，通过 `parseBizCode(Input)` 从输入上下文解析出 bizCode。
- 【强制】`{Name}Ext` 须 `@Extension(bizCode=...)` 并实现对应 `{Name}ExtPt`，bizCode 与 `App` 解析结果一致。
- 【强制】本层只依赖 `extension`（契约），禁止依赖 domain/application/infrastructure。
- 【推荐】新增业务线只新增 app 子模块，不改核心领域（开闭原则）。

## 依赖
- 可依赖：`extension`、`clean-spring-extension-starter`、Google AutoService
- 禁止：`domain`、`application`、`infrastructure`、`interface`、`facade`

## 示例
```java
// bizCode 解析器
@AutoService(App.class)
public class JingDongApp implements App {
    public String parseBizCode(Input input) {
        OrderCreateInput in = (OrderCreateInput) input;
        return in.getItemTags().contains(2) ? JingDongConstants.BIZ_CODE : null;
    }
}

// 扩展实现
@Extension(bizCode = JingDongConstants.BIZ_CODE)
public class OrderExt implements OrderExtPt {
    public Map<String, Object> createAttributes(OrderCreateInput input) {
        Map<String, Object> attrs = new HashMap<>();
        attrs.put("platform", "jingdong");
        return attrs;
    }
}
```

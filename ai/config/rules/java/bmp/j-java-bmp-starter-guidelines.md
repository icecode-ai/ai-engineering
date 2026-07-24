# 业务中台 - starter 启动层规范

## 职责
启动与装配：`Application` 主类、多环境配置（`application*.properties`/`logback-spring.xml`）、集成测试基类、代码生成器（将模板脚手架化为新项目）。

## 包结构
```
{package}.
  Application        @SpringBootApplication 主类
  （test）
    BaseTest         @SpringBootTest 基类
    TestApplication  @ActiveProfiles("testing") 测试启动
    {biz}.module.{Name}ModuleTest   模块测试
    generator        CodeGenerator / CodeTemplateGenerator  脚手架生成器
src/main/resources/
  application.properties / application-{env}.properties
  logback-spring.xml
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| 主类 | `Application @SpringBootApplication` | `Application` |
| 测试基类 | `BaseTest @SpringBootTest` | `BaseTest` |
| 测试启动类 | `TestApplication @ActiveProfiles("testing")` | `TestApplication` |
| 代码生成器 | `CodeGenerator`/`CodeTemplateGenerator` | — |

## 规则
- 【强制】主类包路径为 `{package}.Application`，`@SpringBootApplication` 扫描基础包 `{package}`。
- 【强制】依赖 `interface` + `infrastructure` + 各 `extension-apps` 完成装配，是唯一可打包部署模块（`spring-boot-maven-plugin repackage`）。
- 【强制】多环境配置用 Spring profiles（`testing`/`production`），测试用 `TestApplication` + `test.properties`。
- 【强制】`@CleanLog` 切点配置：`clean.log.patterns[0]={package}.*.module.*`。
- 【推荐】模块测试直接注入 `{Name}Module` Bean 验证编排逻辑，不经过 Controller。

## 依赖
- 可依赖：`interface`、`infrastructure`、各 `extension-apps`、`spring-boot-starter`
- 角色：装配入口，本身不含业务逻辑

## 示例
```java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

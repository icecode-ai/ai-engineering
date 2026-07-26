# Java 开发规范

包含两部分：
1. `通用规范`：Java 通用开发规范，适用于所有 Java 项目
2. `特定架构规范`：基于特定架构的 Java 开发规范。比如： `中台架构` / `DDD架构` / `微服务架构` 等

根据约束力强弱及故障敏感性，规约依次分为三大类：
* `【强制】`：必须遵守，违反可能导致故障、线上问题或协作冲突
* `【推荐】`：建议遵守，提升代码质量与可维护性
* `【参考】`：提供指导，视场景灵活应用

每条规约可附：
* `说明`：引申解释
* `正例`：提倡的写法
* `反例`：需提防的雷区

## 通用规范

### 命名风格

- 【强制】命名不以下划线或美元符号开始/结束。反例：`_name` / `name$` / `Object$`
- 【强制】严禁拼音与英文混合，更不允许中文命名；国际通用名称（如 `alibaba`/`taobao`）可视同英文
- 【强制】杜绝不规范缩写。反例：`AbstractClass`→`AbsClass`、`condition`→`condi`

- 【强制】包名，全小写，`.` 分隔仅一个自然语义单词，包名单数

- 【强制】类名 `UpperCamelCase`，允许全大写后缀如 `DO/DTO/BO`。正例：`UserDO`/`XmlService`
- 【强制】数据模型类命名：`xxxDO`(数据对象) / `xxxDTO`(传输对象)，禁止 `xxxPOJO`
- 【强制】抽象类 `Abstract` 开头；异常类 `Exception` 结尾；测试类以被测类名开头 + `Test` 结尾
- 【推荐】使用设计模式时在类名中体现。正例：`OrderFactory`/`LoginProxy`/`ResourceObserver`

- 【强制】成员变量、方法名、参数名、局部变量 `lowerCamelCase`
- 【强制】常量全大写、下划线分隔、语义完整。正例：`MAX_COUNT`
- 【强制】枚举类，成员全大写下划线分隔。正例：`SUCCESS`
- 【推荐】接口类中，方法不加修饰符（`public` 也省），加 Javadoc，尽量不定义变量
- 【强制】数组定义 `String[] args`，禁用 `String args[]`
- 【强制】POJO 布尔属性不加 `is`，否则部分框架序列化/反序列化时报错
- 【参考】Module/Service/Dao/Facade 方法名前缀：`get`(单个) / `list`(多个) / `page`(分页) / `count`(统计) / `save`(插入) / `remove`(删除) / `update`(修改)

### 注释风格

- 【强制】注释应包含业务含义、简洁易懂
- 【推荐】专有名词与关键字保持英文原文，其余用中文把问题说清楚
- 【推荐】代码修改同步更新注释

- 【强制】类/属性/方法注释用 Javadoc（`/** */`），不用 `//`
- 【强制】属性注释用单行 Javadoc（`/** */`），@Resource 这种依赖注入的不用加注释，其他都加
- 【强制】方法注释，不要省略 入参、出参 注释，`@Override` 的方法，不用加注释，因为其父类已经加了
- 【强制】抽象方法、接口方法必须加 Javadoc，说明做什么、实现要求、调用注意
- 【强制】方法内单行注释在被注释语句上方另起一行用 `//`，如果有多步骤逻辑，加上序号比如 `// 1. {注释}`
- 【强制】枚举字段，用单行 Javadoc（`/** */`），注释说明用途

注释示例参考:
```java
/**
 * 商品库存领域对象
 *
 * @author jim
 * @date 2013-05-21
 */
@Data
public class Inventory implements Aggregate<ItemId> {

    /** 商品ID */
    private ItemId itemId;

    /** 可用库存 */
    private int availableStock;

    /**
     * 库存扣减
     *
     * @param repository 商品库存持久层
     * @param quantity   扣减数量
     */
    public void decrease(InventoryRepository repository, int quantity) {
        Assert.isTrue(availableStock > quantity, "库存不足，无法扣减");

        this.availableStock -= quantity;

        save(repository);
    }
}
```

### 编码风格

- 【强制】统一使用 4 空格缩进，禁用 Tab；续行缩进 4 空格，关闭 IDE 自动检测缩进，以项目配置为准
- 【强制】格式化时不保留源文件原始换行，也不保留首列注释对齐，统一按项目配置重排
- 【强制】控制语句（`if`/`for`/`while`）允许跨行拆分，不强制保持单行

- 【强制】声明区与代码体内连续空行最多 1 行；右大括号 `}` 前最多 1 行空行
- 【强制】`package` 声明与文件头之间最多 1 行空行
- 【强制】字段之间保留 1 行空行（接口中的字段同样）；带注解的字段前后各保留 1 行空行
- 【强制】类头 `class Xxx {` 之后保留 1 行空行；初始化块前后不加空行

- 【强制】多行参数、`try-with-resources` 资源列表、`for` 语句、Record、解构列表均不做竖向列对齐
- 【强制】`throws` 关键字续行时与上一行同缩进

- 【强制】方法声明参数与方法调用参数超长时每参独占一行，左括号 `(` 置于下一行，右括号 `)` 单独成行
- 【强制】`try-with-resources` 资源列表超长时换行，`(` 与 `)` 各自独占一行

- 【强制】`extends`/`throws` 列表超长时每项独占一行，关键字换至下一行

- 【强制】二元运算、三元运算超长时每段独占一行，运算符置于下一行行首
- 【强制】赋值语句超长时换行，`=` 置于下一行行首
- 【强制】方法调用链超长时每个调用独占一行

- 【强制】括号表达式超长时左、右括号各自独占一行
- 【强制】数组初始化超长时每项独占一行，`{` 与 `}` 各自独占一行
- 【强制】简单 Lambda 与简单类保持单行

- 【强制】变量注解、枚举字段注解超长时逐行拆分；参数注解超长时换行
- 【强制】注解参数超长时每项独占一行，`(` 与 `)` 各自独占一行；Record 组件上的注解换行放置
- 【强制】枚举常量超长时逐行拆分

- 【强制】Record 组件超长时每项独占一行，头部 `(` 与 `)` 各自独占一行
- 【强制】解构列表超长时每项独占一行
- 【强制】多异常 `catch (A | B | C)` 超长时每个类型独占一行

- 【强制】Javadoc 中 `@param` 描述之后空一行，`@return` 之后空一行
- 【强制】单行 Javadoc 注释保持单行，不做换行包装

- 【强制】`if/else/for/while/do` 必须用大括号，禁单行形式
- 【强制】多个构造/同名方法按顺序放一起
- 【强制】类内 `属性`、`方法` 顺序：公有/保护 > 私有，static final > static > 非 static

类内 `属性`、`方法` 顺序示例参考:
```java
public class DoubleColorBallFacade {

    public static final String A = "a";

    public static String b;
    
    public String c;
    
    private static final String E = "e";

    private static String f;

    private String g;

    public static PageResponse<DoubleColorBallDTO> m1(int page) {
    }

    protected PageResponse<DoubleColorBallDTO> m2(int page) {
    }

    PageResponse<DoubleColorBallDTO> m3(int page) {
    }
    
    private static PageResponse<DoubleColorBallDTO> m4(int page) {
    }

    private PageResponse<DoubleColorBallDTO> m5(int page) {
    }
}
```

### OOP 规约

- 【强制】对外提供的接口，包括 `http`、`RPC` 接口等，不要修改方法签名，避免兼容性问题；过时接口加 `@Deprecated` 并说明新接口

- 【强制】不通过对象引用访问静态成员，直接用类名

- 【强制】单个方法不要超过50行，为了性能，快速垃圾回收，尽量将方法拆细，比如从数据库查出来一个List，只需要计算最终结果时，单独抽成一个方法

- 【强制】所有覆写方法加 `@Override`
- 【强制】可变参数须同类型同语义且放参数列表最后，避免用 `Object`
- 【强制】不使用过时的类/方法
- 【强制】`equals` 用常量或确定有值的对象调用。正例：`"test".equals(obj)`；推荐 `Objects#equals`
- 【强制】包装类对象值比较一律用 `equals`（`Integer` 缓存仅 -128~127）
- 【强制】POJO 属性用 `包装类型`；RPC 返回值/参数用 `包装类型`；局部变量推荐 `基本类型`
- 【强制】`DO/DTO` 等 POJO 不设属性默认值
- 【强制】构造方法禁止业务逻辑，初始化放 `init` 方法
- 【推荐】setter 参数名与成员一致；getter/setter 不加业务逻辑
- 【推荐】循环内字符串拼接用 `StringBuilder.append`
- 【推荐】`final` 用于：不可继承类、不可变引用域、不可重写方法、不可重赋值局部变量
- 【推荐】慎用 `Object.clone`（默认浅拷贝）
- 【推荐】访问控制从严：工具类无 `public` 构造；仅本类用的成员 `private`；仅继承类用的 `protected`

### 常量定义

- 【强制】禁止魔法值（未经定义的常量）直接出现在代码中
- 【强制】`long`/`Long` 赋值用大写 `L`，禁用小写 `l`（与 1 混淆）
- 【推荐】值在固定范围内且带延伸属性时用枚举。正例：`MONDAY(1)...SUNDAY(7)`

### 集合处理

- 【强制】重写 `equals` 必须重写 `hashCode`；`Set` 元素与 `Map` 键必须重写两者
- 【强制】`ArrayList.subList` 不可强转 `ArrayList`（返回内部类视图），`subList` 场景下修改原集合元素个数会抛 `ConcurrentModificationException`
- 【强制】集合转数组用 `toArray(T[] array)`，数组大小为 `list.size()`
- 【强制】`Arrays.asList()` 返回的是不可修改集合，`add/remove/clear` 抛 `UnsupportedOperationException`
- 【强制】`<? extends T>` 不能 `add`，`<? super T>` 不能 `get`（PECS 原则）
- 【强制】`foreach` 中不做 `remove/add`，用 `Iterator`；并发需加锁
- 【强制】`Comparator` 须满足自反性、传递性、对称性，否则 `sort` 抛 `IllegalArgumentException`
- 【推荐】集合初始化指定容量。`HashMap` 容量 = 元素数/0.75 + 1
- 【推荐】遍历 Map KV 用 `entrySet` 而非 `keySet`（少一次遍历）
- 【推荐】注意 Map K/V 对 null 的支持差异：`ConcurrentHashMap` K/V 均不允许 null
- 【参考】利用集合有序性/稳定性；`Set` 去重优于 `List.contains` 遍历

### 并发处理

- 【强制】单例保证线程安全，其方法也保证线程安全
- 【强制】创建线程/线程池指定有意义名称
- 【强制】线程资源通过线程池提供，禁用显式 `new Thread`
- 【强制】线程池用 `ThreadPoolExecutor`，禁用 `Executors`（`Fixed/Single` 队列 `Integer.MAX_VALUE` 致 OOM；`Cached/Scheduled` 线程数 `Integer.MAX_VALUE` 致 OOM）
- 【强制】`SimpleDateFormat` 线程不安全，不要 `static`，或加锁/用 `ThreadLocal`；JDK8+ 用 `DateTimeFormatter`
- 【强制】高并发考量锁性能：能用无锁结构不用锁；能锁区块不锁方法体；能用对象锁不用类锁；锁块内不调 RPC
- 【强制】多资源加锁保持一致顺序，防死锁
- 【强制】并发修改同记录加锁（应用层/缓存/数据库乐观锁 version）；冲突概率 <20% 用乐观锁，重试≥3 次
- 【强制】定时任务多 `TimeTask` 用 `ScheduledExecutorService`，不用 `Timer`（其一异常会终止全部）
- 【推荐】`CountDownLatch` 子线程确保 `countDown` 执行（catch 异常），避免主线程超时
- 【推荐】避免 `Random` 多线程共享，用 `ThreadLocalRandom`（JDK7+）
- 【推荐】双重检查锁延迟初始化，目标属性声明 `volatile`
- 【参考】`volatile` 解决一写多读内存可见性；多写仍不安全。`count++` 用 `AtomicInteger` 或 JDK8 `LongAdder`
- 【参考】`HashMap` resize 高并发可能死链致 CPU 飙升
- 【参考】`ThreadLocal` 建议 `static` 修饰，无法解决共享对象更新问题

### 控制语句

- 【强制】`switch` 每个 `case` 用 `break/return` 终止或注释 fall-through；必须含 `default` 且放最后
- 【推荐】边缘场景少用 if-else，用卫语句提前 return；if-else 不超 3 层
- 【推荐】复杂条件判断结果赋值给有意义的布尔变量
- 【推荐】循环体内避免定义对象、获取连接、不必要 try-catch（移到循环外）
- 【推荐】批量操作接口做入参保护
- 【参考】参数校验场景：低频方法、执行开销大的方法、高稳定性方法、对外接口、敏感权限入口
- 【参考】免校验场景：高频被循环/底层方法（注明外部校验要求）、确定调用方已校验的 private 方法

### 异常处理

- 【强制】可通过预检查规避的 `RuntimeException`（如 NPE/`IndexOutOfBoundsException`）不应 catch。正例：`if (obj != null) {...}`
- 【强制】异常不做流程/条件控制
- 【强制】仅弱依赖场景加 try-catch（最外层已有统一异常拦截，避免抛出用户无法理解的内容）；catch 统一用 Throwable 捕获
- 【强制】禁止大段 try-catch；稳定与非稳定代码分段处理，各自独立 try-catch
- 【强制】事务代码 catch 异常后如需回滚须手动回滚
- 【强制】`finally` 块必须关闭资源/流（可 try-catch）；JDK7+ 用 try-with-resources
- 【强制】`finally` 块禁用 `return`
- 【推荐】防 NPE：确定性返回基本类型时用基本类型；可能为 null 的单个对象或包装类型用 `Optional` 包装
- 【推荐】不要返回 null 集合，返回空集合

### 日志规约

- 【强制】不直接用 Log4j/Logback API，依赖 SLF4J 门面
- 【强制】trace/debug/info 日志用条件输出或占位符 `{}`，避免无效字符串拼接

### 其他

- 【强制】正则表达式用预编译（`Pattern` 定义在方法体外）
- 【强制】获取毫秒数用 `System.currentTimeMillis()`，不用 `new Date().getTime()`；纳秒用 `System.nanoTime()`；JDK8 统计时间用 `Instant`

### MySQL 建表规约

- 【强制】是否概念字段用 `is_xxx`，类型 `unsigned tinyint`（1 是/0 否）；非负字段必须 unsigned
- 【强制】表名/字段名小写字母或数字，禁数字开头，禁两下划线间只出现数字
- 【强制】表名不用复数
- 【强制】禁用保留字（`desc`/`range`/`match` 等）
- 【强制】索引命名：主键 `pk_字段名`、唯一 `uk_字段名`、普通 `idx_字段名`
- 【强制】小数用 `decimal`，禁 `float`/`double`
- 【强制】等长字符串用 `char`
- 【强制】`varchar` 长度不超 5000；超长用 `text` 独立表关联
- 【强制】表必备三字段：`id`(主键 unsigned bigint 自增)、`gmt_create`、`gmt_modified`(datetime)
- 【推荐】表名加「业务名称_表作用」。正例：`tiger_task`
- 【推荐】修改字段含义/追加状态时同步更新字段注释
- 【推荐】字段适当冗余提升查询性能（非频繁修改、非超长 varchar/text）
- 【参考】合适的存储长度节约空间并提升检索速度

### MySQL 索引规约

- 【强制】业务唯一字段（含组合）必须建唯一索引
- 【强制】超 3 表禁 join；join 字段类型必须一致且被关联字段有索引
- 【强制】`varchar` 建索引须指定长度（一般 20 区分度 90%+）
- 【强制】页面搜索禁左模糊/全模糊（走搜索引擎）
- 【推荐】`order by` 字段放组合索引最后，避免 file_sort
- 【推荐】利用覆盖索引避免回表
- 【推荐】超多分页用延迟关联/子查询优化
- 【推荐】SQL 性能目标至少 `range`，要求 `ref`，最好 `consts`
- 【推荐】组合索引区分度最高的在最左；等号条件列前置
- 【推荐】防字段类型隐式转换致索引失效

### MySQL SQL 语句

- 【强制】用 `count(*)`，不用 `count(列名)`/`count(常量)`
- 【强制】`count(distinct col1,col2)` 若一列全 NULL 返回 0
- 【强制】`sum(col)` 列全 NULL 返回 NULL，注意 NPE。正例：`SELECT IF(ISNULL(SUM(g)),0,SUM(g))`
- 【强制】用 `ISNULL()` 判 NULL；`NULL` 与任何值比较都为 `NULL`
- 【强制】分页 count 为 0 直接返回
- 【强制】禁用外键与级联，应用层解决
- 【强制】禁用存储过程
- 【强制】删除/修改记录前先 select 确认
- 【推荐】`in` 集合元素控制 1000 以内
- 【参考】全球化字符用 utf-8（表情用 utf8mb4）
- 【参考】不建议在开发代码用 `TRUNCATE TABLE`

### MySQL ORM 映射

- 【强制】DB 布尔字段用 `is_` 前缀，POJO 侧不加 `is`（见命名风格），`resultMap` 中映射
- 【强制】禁用 `HashMap`/`Hashtable` 作查询结果集输出
- 【推荐】不写大而全更新接口，不更新无改动字段
- 【参考】`@Transactional` 不滥用，考虑缓存/搜索引擎/消息补偿等回滚方案

## 特定架构规范

按项目分层结构识别架构模式：
* `识别时`：选用对应规范
* `未识别时`：跳过读取规范文件

| 架构模式 | 识别方式 | 规范文件 |
|---|---|---|
| 中台架构 | 包含 `{artifactId}-application`、`{artifactId}-client`、`{artifactId}-domain`、`{artifactId}-extension`、`{artifactId}-facade`、`{artifactId}-infrastructure`、`{artifactId}-interface`、`{artifactId}-starter` 模块 | `ai/config/rules/java/bmp/java-bmp-all-guidelines.md` |
| DDD架构 | 包含 `{artifactId}-application`、`{artifactId}-client`、`{artifactId}-domain`、`{artifactId}-facade`、`{artifactId}-infrastructure`、`{artifactId}-interface`、`{artifactId}-starter` 模块，不包含 `{artifactId}-extension` 模块 | `ai/config/rules/java/ddd/java-ddd-all-guidelines.md` |
| 微服务架构 | 包含 `{artifactId}-application`、`{artifactId}-client`、`{artifactId}-facade`、`{artifactId}-infrastructure`、`{artifactId}-interface`、`{artifactId}-starter` 模块，不包含 `{artifactId}-domain`、`{artifactId}-extension` 模块 | `ai/config/rules/java/ms/java-ms-all-guidelines.md` |

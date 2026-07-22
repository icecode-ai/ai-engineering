# Java 开发规范

包含两部分：
1. 通用规范：Java 通用开发规范，适用于所有 Java 项目
2. 特定架构规范：基于特定架构的分层规范，比如 业务中台 / 领域模型 / 微服务

根据约束力强弱及故障敏感性，规约依次分为三大类：

| 级别 | 含义 |
|---|---|
| 【强制】 | 必须遵守，违反可能导致故障、线上问题或协作冲突 |
| 【推荐】 | 建议遵守，提升代码质量与可维护性 |
| 【参考】 | 提供指导，视场景灵活应用 |

每条规约可附「说明」（引申解释）、「正例」（提倡的写法）、「反例」（需提防的雷区）。

## 通用规范

### 命名风格

- 【强制】命名不以下划线或美元符号开始/结束。反例：`_name` / `name$` / `Object$`
- 【强制】严禁拼音与英文混合，更不允许中文命名；国际通用名称（如 `alibaba`/`taobao`）可视同英文。
- 【强制】类名 `UpperCamelCase`，例外：`DO/BO/DTO/VO/AO` 后缀。正例：`UserDO`/`XmlService`
- 【强制】方法名、参数名、成员变量、局部变量 `lowerCamelCase`。
- 【强制】常量全大写、下划线分隔、语义完整。正例：`MAX_STOCK_COUNT`
- 【强制】抽象类 `Abstract`/`Base` 开头；异常类 `Exception` 结尾；测试类以被测类名开头 + `Test` 结尾。
- 【强制】数组定义 `String[] args`，禁用 `String args[]`。
- 【强制】POJO 布尔属性不加 `is`，否则部分框架反向解析序列化错误。
- 【强制】包名全小写，点分隔仅一个自然语义单词，包名单数。
- 【强制】杜绝不规范缩写。反例：`AbstractClass`→`AbsClass`、`condition`→`condi`
- 【推荐】使用设计模式时在类名中体现。正例：`OrderFactory`/`LoginProxy`/`ResourceObserver`
- 【推荐】接口方法不加修饰符（`public` 也省）并加 Javadoc；接口尽量不定义变量。
- 【强制】Service/DAO 暴露为接口，实现类用 `Impl` 后缀。正例：`CacheServiceImpl` 实现 `CacheService`
- 【参考】枚举类名建议 `Enum` 后缀，成员全大写下划线分隔。正例：`DealStatusEnum`/`SUCCESS`
- 【参考】各层命名：
  - Service/DAO 方法：`get`(单个) / `list`(多个) / `count`(统计) / `save|insert`(插入) / `remove|delete`(删除) / `update`(修改)
  - 领域模型：`xxxDO`(数据对象) / `xxxDTO`(传输对象) / `xxxVO`(展示对象)，禁止 `xxxPOJO`

### 常量定义

- 【强制】禁止魔法值（未经定义的常量）直接出现在代码中。
- 【强制】`long`/`Long` 赋值用大写 `L`，禁用小写 `l`（与 1 混淆）。
- 【推荐】常量按功能归类分文件维护，不要一个大而全常量类。如 `CacheConsts`/`ConfigConsts`
- 【推荐】常量复用五层：跨应用(`client.jar` constant) / 应用内(`modules` constant) / 子工程 / 包内 / 类内 `private static final`。
- 【推荐】值在固定范围内且带延伸属性时用枚举。正例：`MONDAY(1)...SUNDAY(7)`

### OOP 规约

- 【强制】不通过对象引用访问静态成员，直接用类名。
- 【强制】所有覆写方法加 `@Override`。
- 【强制】可变参数须同类型同语义且放参数列表最后，避免用 `Object`。
- 【强制】外部调用或二方库接口不修改方法签名；过时接口加 `@Deprecated` 并说明新接口。
- 【强制】不使用过时的类/方法。
- 【强制】`equals` 用常量或确定有值的对象调用。正例：`"test".equals(obj)`；推荐 `Objects#equals`。
- 【强制】包装类对象值比较一律用 `equals`（`Integer` 缓存仅 -128~127）。
- 【强制】POJO 属性用包装类型；RPC 返回值/参数用包装类型；局部变量推荐基本类型。
- 【强制】`DO/DTO/VO` 等 POJO 不设属性默认值。
- 【强制】序列化类新增属性不改 `serialVersionUID`（不兼容升级才改）。
- 【强制】构造方法禁止业务逻辑，初始化放 `init` 方法。
- 【强制】POJO 必须写 `toString`，继承时加 `super.toString`。
- 【推荐】`String.split` 结果按下标访问前检查长度。
- 【推荐】多个构造/同名方法按顺序放一起。
- 【推荐】类内方法顺序：公有/保护 > 私有 > getter/setter。
- 【推荐】setter 参数名与成员一致；getter/setter 不加业务逻辑。
- 【推荐】循环内字符串拼接用 `StringBuilder.append`。
- 【推荐】`final` 用于：不可继承类、不可变引用域、不可重写方法、不可重赋值局部变量。
- 【推荐】慎用 `Object.clone`（默认浅拷贝）。
- 【推荐】访问控制从严：工具类无 public 构造；仅本类用的成员 private；仅继承类用的 protected。

### 集合处理

- 【强制】重写 `equals` 必须重写 `hashCode`；`Set` 元素与 `Map` 键必须重写两者。
- 【强制】`ArrayList.subList` 不可强转 `ArrayList`（返回内部类视图）。
- 【强制】`subList` 场景下修改原集合元素个数会抛 `ConcurrentModificationException`。
- 【强制】集合转数组用 `toArray(T[] array)`，数组大小为 `list.size()`。
- 【强制】`Arrays.asList()` 返回不可修改集合，`add/remove/clear` 抛 `UnsupportedOperationException`。
- 【强制】`<? extends T>` 不能 `add`，`<? super T>` 不能 `get`（PECS 原则）。
- 【强制】`foreach` 中不做 `remove/add`，用 `Iterator`；并发需加锁。
- 【强制】`Comparator` 须满足自反性、传递性、对称性，否则 `sort` 抛 `IllegalArgumentException`。
- 【推荐】集合初始化指定容量。`HashMap` 容量 = 元素数/0.75 + 1。
- 【推荐】遍历 Map KV 用 `entrySet` 而非 `keySet`（少一次遍历）；JDK8 用 `Map.forEach`。
- 【推荐】注意 Map K/V 对 null 的支持差异：`ConcurrentHashMap` K/V 均不允许 null。
- 【参考】利用集合有序性/稳定性；`Set` 去重优于 `List.contains` 遍历。

### 并发处理

- 【强制】单例保证线程安全，其方法也保证线程安全。
- 【强制】创建线程/线程池指定有意义名称。
- 【强制】线程资源通过线程池提供，禁用显式 `new Thread`。
- 【强制】线程池用 `ThreadPoolExecutor`，禁用 `Executors`（`Fixed/Single` 队列 `Integer.MAX_VALUE` 致 OOM；`Cached/Scheduled` 线程数 `Integer.MAX_VALUE` 致 OOM）。
- 【强制】`SimpleDateFormat` 线程不安全，不要 `static`，或加锁/用 `ThreadLocal`；JDK8+ 用 `DateTimeFormatter`。
- 【强制】高并发考量锁性能：能用无锁结构不用锁；能锁区块不锁方法体；能用对象锁不用类锁；锁块内不调 RPC。
- 【强制】多资源加锁保持一致顺序，防死锁。
- 【强制】并发修改同记录加锁（应用层/缓存/数据库乐观锁 version）；冲突概率 <20% 用乐观锁，重试≥3 次。
- 【强制】定时任务多 `TimeTask` 用 `ScheduledExecutorService`，不用 `Timer`（其一异常会终止全部）。
- 【推荐】`CountDownLatch` 子线程确保 `countDown` 执行（catch 异常），避免主线程超时。
- 【推荐】避免 `Random` 多线程共享，用 `ThreadLocalRandom`（JDK7+）。
- 【推荐】双重检查锁延迟初始化，目标属性声明 `volatile`。
- 【参考】`volatile` 解决一写多读内存可见性；多写仍不安全。`count++` 用 `AtomicInteger` 或 JDK8 `LongAdder`。
- 【参考】`HashMap` resize 高并发可能死链致 CPU 飙升。
- 【参考】`ThreadLocal` 建议 `static` 修饰，无法解决共享对象更新问题。

### 控制语句

- 【强制】`switch` 每个 `case` 用 `break/return` 终止或注释 fall-through；必须含 `default` 且放最后。
- 【强制】`if/else/for/while/do` 必须用大括号，禁单行形式。
- 【推荐】异常分支少用 if-else，用卫语句提前 return；if-else 不超 3 层。
- 【推荐】复杂条件判断结果赋值给有意义的布尔变量。
- 【推荐】循环体内避免定义对象、获取连接、不必要 try-catch（移到循环外）。
- 【推荐】批量操作接口做入参保护。
- 【参考】参数校验场景：低频方法、执行开销大的方法、高稳定性方法、对外接口、敏感权限入口。
- 【参考】免校验场景：高频被循环/底层方法（注明外部校验要求）、确定调用方已校验的 private 方法。

### 注释规约

- 【强制】类/属性/方法注释用 Javadoc（`/** */`），不用 `//`。
- 【强制】抽象方法（含接口方法）必须 Javadoc，说明做什么、实现要求、调用注意。
- 【强制】所有类必须添加创建者和创建日期。
- 【强制】方法内单行注释在被注释语句上方另起一行用 `//`；多行用 `/* */`，与代码对齐。
- 【强制】枚举字段必须注释说明用途。
- 【推荐】专有名词与关键字保持英文原文，其余用中文把问题说清楚。
- 【推荐】代码修改同步更新注释。
- 【参考】注释掉的代码无用则直接删除（仓库有历史）；如需保留须上方说明动机。
- 【参考】特殊标记 `TODO`/`FIXME` 注明标记人、时间、预计处理时间，及时清理。

### 其他

- 【强制】正则表达式用预编译（`Pattern` 定义在方法体外）。
- 【强制】`Math.random()` 返回 `double`，范围 `[0,1)`；取整随机数用 `Random.nextInt/nextLong`。
- 【强制】获取毫秒数用 `System.currentTimeMillis()`，不用 `new Date().getTime()`；纳秒用 `System.nanoTime()`；JDK8 统计时间用 `Instant`。
- 【推荐】数据结构构造/初始化指定大小，防无限增长吃光内存。
- 【推荐】明确停止使用的代码/配置坚决清理。

### 异常处理

- 【强制】可通过预检查规避的 `RuntimeException`（如 NPE/`IndexOutOfBoundsException`）不应 catch。正例：`if (obj != null) {...}`
- 【强制】异常不做流程/条件控制。
- 【强制】禁止大段 try-catch；区分稳定/非稳定代码，分类 catch。
- 【强制】捕获异常必须处理，不处理则抛给调用者；最外层业务必须转为用户可理解内容。
- 【强制】事务代码 catch 异常后如需回滚须手动回滚。
- 【强制】`finally` 块必须关闭资源/流（可 try-catch）；JDK7+ 用 try-with-resources。
- 【强制】`finally` 块禁用 `return`。
- 【强制】捕获异常与抛异常完全匹配或为父类。
- 【推荐】方法可返回 null，但须注释说明；调用方须做 null 判断防 NPE。
- 【推荐】防 NPE 场景：基本类型 return 包装对象（拆箱 NPE）、DB 查询结果、集合元素、远程调用返回、Session 数据、级联调用 `obj.getA().getB()`。推荐 `Optional`。
- 【推荐】区分 unchecked/checked，不直接抛 `RuntimeException`/`Exception`/`Throwable`，用有业务含义的自定义异常（如 `DAOException`/`ServiceException`）。
- 【参考】对外 http/api 用错误码；应用内部用异常；跨应用 RPC 优先 `Result` 封装 `isSuccess()/错误码/简短信息`。
- 【参考】遵循 DRY，重复代码抽取共性方法/公共类/共用模块。

### 日志规约

- 【强制】不直接用 Log4j/Logback API，依赖 SLF4J 门面。
- 【强制】trace/debug/info 日志用条件输出或占位符 `{}`，避免无效字符串拼接。

### MySQL 建表规约

- 【强制】是否概念字段用 `is_xxx`，类型 `unsigned tinyint`（1 是/0 否）；非负字段必须 unsigned。
- 【强制】表名/字段名小写字母或数字，禁数字开头，禁两下划线间只出现数字。
- 【强制】表名不用复数。
- 【强制】禁用保留字（`desc`/`range`/`match` 等）。
- 【强制】索引命名：主键 `pk_字段名`、唯一 `uk_字段名`、普通 `idx_字段名`。
- 【强制】小数用 `decimal`，禁 `float`/`double`。
- 【强制】等长字符串用 `char`。
- 【强制】`varchar` 长度不超 5000；超长用 `text` 独立表关联。
- 【强制】表必备三字段：`id`(主键 unsigned bigint 自增)、`gmt_create`、`gmt_modified`(datetime)。
- 【推荐】表名加「业务名称_表作用」。正例：`tiger_task`
- 【推荐】库名与应用名一致。
- 【推荐】修改字段含义/追加状态时同步更新字段注释。
- 【推荐】字段适当冗余提升查询性能（非频繁修改、非超长 varchar/text）。
- 【推荐】单表超 500 万行或 2GB 才分库分表。
- 【参考】合适的存储长度节约空间并提升检索速度。

### MySQL 索引规约

- 【强制】业务唯一字段（含组合）必须建唯一索引。
- 【强制】超 3 表禁 join；join 字段类型必须一致且被关联字段有索引。
- 【强制】`varchar` 建索引须指定长度（一般 20 区分度 90%+）。
- 【强制】页面搜索禁左模糊/全模糊（走搜索引擎）。
- 【推荐】`order by` 字段放组合索引最后，避免 file_sort。
- 【推荐】利用覆盖索引避免回表。
- 【推荐】超多分页用延迟关联/子查询优化。
- 【推荐】SQL 性能目标至少 `range`，要求 `ref`，最好 `consts`。
- 【推荐】组合索引区分度最高的在最左；等号条件列前置。
- 【推荐】防字段类型隐式转换致索引失效。

### MySQL SQL 语句

- 【强制】用 `count(*)`，不用 `count(列名)`/`count(常量)`。
- 【强制】`count(distinct col1,col2)` 若一列全 NULL 返回 0。
- 【强制】`sum(col)` 列全 NULL 返回 NULL，注意 NPE。正例：`SELECT IF(ISNULL(SUM(g)),0,SUM(g))`
- 【强制】用 `ISNULL()` 判 NULL；`NULL` 与任何值比较都为 `NULL`。
- 【强制】分页 count 为 0 直接返回。
- 【强制】禁用外键与级联，应用层解决。
- 【强制】禁用存储过程。
- 【强制】删除/修改记录前先 select 确认。
- 【推荐】`in` 集合元素控制 1000 以内。
- 【参考】全球化字符用 utf-8（表情用 utf8mb4）。
- 【参考】不建议在开发代码用 `TRUNCATE TABLE`。

### MySQL ORM 映射

- 【强制】表查询禁用 `*`，明确写字段列表。
- 【强制】POJO 布尔属性不加 `is`，DB 字段加 `is_`，`resultMap` 中映射。
- 【强制】不用 `resultClass` 当返回参数，必须定义 resultMap。
- 【强制】禁用 `HashMap`/`Hashtable` 作查询结果集输出。
- 【强制】更新记录须同时更新 `gmt_modified`。
- 【推荐】不写大而全更新接口，不更新无改动字段。
- 【参考】`@Transactional` 不滥用，考虑缓存/搜索引擎/消息补偿等回滚方案。

## 特定架构规范

按项目分层结构识别架构模式，选用对应规范：

| 架构模式 | 识别方式 | 规范文件 |
|---|---|---|
| 业务中台架构 | 存在 `{artifactId}-extension`（扩展点 SPI 定义）+ `{artifactId}-extension-apps`（按 bizCode 的业务变体插件）模块，且 `{artifactId}-domain` 含聚合根与 `ExtensionExecutor` 调用 | `ai/config/rules/java/a-java-bmp-guidelines.md` |
| 领域模型架构 | 存在 `{artifactId}-domain`（聚合根/值对象/领域服务/领域事件/Repository 端口）+ `{artifactId}-facade`，但无 `-extension`/`-extension-apps` 模块 | `ai/config/rules/java/k-java-ddd-guidelines.md` |
| 微服务架构 | 无独立 `{artifactId}-domain` 模块；`{package}.{biz}.repository` 下 `*Repository` 为具体 `@Component`（非端口接口）；`*Assembler` 直接 Command↔DO 转换（无领域实体中间层） | `ai/config/rules/java/s-java-ms-guidelines.md` |

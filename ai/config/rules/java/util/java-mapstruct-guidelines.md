# MapStruct 使用指南

MapStruct 是编译期 Bean 映射代码生成工具：生成纯方法调用代码(无反射)、编译期类型安全，漏映射在构建期即报错。本文以示例展示其用法

## 定义 Mapper（基本映射）

用 `interface` + `@Mapper` 定义，通过 `Mappers.getMapper()` 获取实例并暴露 `INSTANCE`。同名属性自动映射；名称不一致用 `@Mapping(target, source)` 显式声明

```java
/**
 * 行业数据包装器
 *
 * <p>DTO <-> Domain 数据转换包装器</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Mapper
public interface BlockAssembler {

    BlockAssembler INSTANCE = Mappers.getMapper(BlockAssembler.class);

    @Mapping(target = "gmtModified", ignore = true)
    @Mapping(target = "gmtCreate", ignore = true)
    BlockDO to(SeBlockDTO blockDTO);

    SeBlockDTO to(BlockDO blockDO);
}
```

### 显式映射（仅映射声明字段）

`@BeanMapping(ignoreByDefault = true)` 关闭自动映射，只保留 `@Mapping` 显式声明的字段，且不告警：

```java
@BeanMapping(ignoreByDefault = true)
@Mapping(target = "name", source = "groupName")
ShelveEntity to(ShelveDto source);
```

## 三、类型转换

MapStruct 自动处理常见转换：基本型与包装型(含 null 判断)、数值/`BigDecimal` 与 `String`、`Date`/`java.time.*` 与 `String`、枚举与 `String`、`UUID`/`URL`/`Locale` 与 `String` 等。数值用 `numberFormat`，日期用 `dateFormat`

```java
@Mapping(target = "price", source = "price", numberFormat = "$#.00")
@Mapping(target = "manufacturingDate", source = "manufacturingDate", dateFormat = "yyyy-MM-dd")
CarDto to(Car car);
```

`long`→`int` 等大转小会丢精度，可用 `@Mapper(typeConversionPolicy = ReportingPolicy.WARN)` 监控

## 四、集合与 Map 映射

集合映射自动逐元素转换。接口到实现的默认实例化：`List`→`ArrayList`、`Set`→`LinkedHashSet`、`SortedSet`→`TreeSet`、`Map`→`LinkedHashMap`、`SortedMap`→`TreeMap`

JPA 实体含 `add` 方法时，用 `ADDER_PREFERRED` 通过 adder 建立父子关系（目标集合须已初始化）：

```java
@Mapper(collectionMappingStrategy = CollectionMappingStrategy.ADDER_PREFERRED)
public interface OrderMapper {
    Order to(OrderDto dto);
}
```

`Map<K,V>` 间映射用 `@MapMapping` 单独控制键值格式：

```java
@MapMapping(keyDateFormat = "yyyy-MM-dd", valueNumberFormat = "$#.00")
Map<String, String> toStringMap(Map<LocalDate, BigDecimal> source);
```

## 五、高级映射

### 多源参数

多个源参数合并到一个目标。若多个源含同名属性，须用 `参数名.属性名` 消歧；也可直接引用非 Bean 源参数。全部源为 null 时返回 null

```java
@Mapping(target = "description", source = "person.description")
@Mapping(target = "houseNumber", source = "address.houseNo")
DeliveryAddressDto to(Person person, Address address);
```

### 更新已有实例

用 `@MappingTarget` 标注被更新参数，避免新建对象。返回 `void` 或目标类型(便于链式)：

```java
void updateFromDto(SeBlockDTO dto, @MappingTarget BlockDO blockDO);

Car update(CarDto dto, @MappingTarget Car car);
```

### 嵌套属性展开

`@Mapping(target = ".", source = "record")` 将嵌套源 Bean 的所有属性平铺到当前目标，适合 层级↔扁平 转换。冲突处用显式 `@Mapping` 解决：

```java
@Mapping(target = "name", source = "record.name")
@Mapping(target = ".", source = "record")
@Mapping(target = ".", source = "account")
Customer to(CustomerDto dto);
```

### 表达式与常量

`expression = "java(...)"` 内联 Java 代码（MapStruct 不校验语法，编译期暴露错误）；`defaultExpression` 仅源为 null 时执行；`defaultValue` 源为 null 时的字符串兜底；`constant` 始终赋固定值（不可与 `source` 同用）。复杂表达式用 `@Mapper(imports = X.class)` 引入类

```java
@Mapper(imports = UUID.class)
public interface OrderAssembler {

    @Mapping(target = "id", source = "sourceId", defaultExpression = "java(UUID.randomUUID().toString())")
    @Mapping(target = "createTime", expression = "java(new java.util.Date())")
    @Mapping(target = "status", constant = "INIT")
    Order to(OrderDto dto);
}
```

## 六、Null 处理

源集合/Map 为 null 时返回空集合而非 null：

```java
@BeanMapping(nullValueMappingStrategy = NullValueMappingStrategy.RETURN_DEFAULT)
List<ItemDto> to(List<Item> items);
```

更新方法做局部更新时，源属性为 null 保留原值（patch 场景）：

```java
@BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
void updateFromDto(OrderDto dto, @MappingTarget Order order);
```

三大策略对照：

| 策略 | 作用域 | 取值 |
|---|---|---|
| `nullValueMappingStrategy` | 整个方法(源参数为 null) | `RETURN_NULL`(默认) / `RETURN_DEFAULT`(空 bean/集合) |
| `nullValuePropertyMappingStrategy` | 单属性(update 方法) | `SET_TO_NULL`(默认) / `SET_TO_DEFAULT` / `IGNORE`(保留原值) |
| `nullValueCheckStrategy` | 单属性 null 检查 | `ON_IMPLICIT_CONVERSION`(默认) / `ALWAYS` |

### 条件映射

`@Condition` 标注 `boolean` 返回方法，替代默认 null 检查决定是否映射该属性；`@SourceParameterCondition` 决定是否映射整个源参数：

```java
@Mapper
public interface UserMapper {

    @Condition
    default boolean isNotEmpty(String value) {
        return value != null && !value.isEmpty();
    }

    @SourceParameterCondition
    default boolean hasId(User user) {
        return user != null && user.getId() != null;
    }

    UserDto to(User user);
}
```

## 七、配置复用

### 继承与反向

`@InheritConfiguration` 继承已有方法的 `@Mapping` 配置；`@InheritInverseConfiguration` 自动交换 source/target 生成反向方法。注意：反向继承时 `expression`/`defaultExpression`/`defaultValue`/`constant` 被静默忽略，须重新声明

```java
@Mapper
public interface CarAssembler {

    @Mapping(target = "manufacturer", source = "make")
    @Mapping(target = "seatCount", source = "numberOfSeats")
    CarDto to(Car car);

    @InheritConfiguration(name = "to")
    CarDto toWithExtra(Car car, String extra);

    @InheritInverseConfiguration
    Car from(CarDto dto);
}
```

### 共享配置

`@MapperConfig` 定义项目级中央配置，各 Mapper 用 `@Mapper(config = ...)` 引用。`@Mapper` 属性覆盖配置，`uses` 等列表属性合并：

```java
@MapperConfig(unmappedTargetPolicy = ReportingPolicy.ERROR, uses = DateMapper.class)
public interface CentralConfig {
}

@Mapper(config = CentralConfig.class)
public interface OrderAssembler {
    Order to(OrderDto dto);
}
```

## 八、自定义映射

### 手写 default 方法

MapStruct 无法生成的特殊逻辑，用 `default` 方法写在 Mapper 接口内，生成代码按参数/返回类型自动调用：

```java
@Mapper
public interface CarMapper {

    CarDto to(Car car);

    default PersonDto to(Person person) {
        if (person == null) {
            return null;
        }
        // 手写转换逻辑
    }
}
```

### 前后置回调

`@BeforeMapping`/`@AfterMapping` 处理横切逻辑。无参前置方法在 null 检查与目标构造前执行；含 `@MappingTarget` 的前置方法在目标构造后执行；`@AfterMapping` 在 return 前执行。同类型内多方法顺序不保证

```java
@Mapper
public abstract class OrderMapper {

    @BeforeMapping
    protected void logStart(OrderDto dto) {
        // 目标构造前
    }

    @AfterMapping
    protected void fillDefaults(OrderDto dto, @MappingTarget Order order) {
        if (order.getStatus() == null) {
            order.setStatus("INIT");
        }
    }

    public abstract Order to(OrderDto dto);
}
```

### 限定符消歧

同签名多用途方法用 `@Named("别名")` 消歧，通过 `qualifiedByName` 指定；也可用自定义 `@Qualifier` 注解(retention 须 `CLASS`)经 `qualifiedBy` 引用：

```java
@Mapper
public interface TitleMapper {

    @Named("englishToGerman")
    default String translateEnDe(String en) { /* ... */ }

    @Named("englishToFrench")
    default String translateEnFr(String en) { /* ... */ }

    @Mapping(target = "title", qualifiedByName = "englishToGerman")
    GermanDoc toGerman(Document doc);
}
```

### 对象工厂

`@ObjectFactory` 标注工厂方法自定义目标实例创建，优先级高于构造器；可访问映射源作为参数：

```java
@Mapper
public interface CarMapper {

    @ObjectFactory
    default CarDto createCarDto(Car car) {
        CarDto dto = new CarDto();
        dto.setSourceType(car.getClass().getSimpleName());
        return dto;
    }

    CarDto to(Car car);
}
```
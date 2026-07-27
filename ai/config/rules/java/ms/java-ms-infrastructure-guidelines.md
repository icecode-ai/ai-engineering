# 微服务 - infrastructure 基础设施层规范

## 职责
持久层/出站适配器：DB 访问（Repository 具体类/DAO/DO）、消息生产者、多数据源配置。可调用 facade 封装二/三方服务调用。与 DDD/BMP 的区别：**`*Repository` 为具体 `@Component` 类（非端口接口实现）**，查询条件/消息类型也放在本层 `types` 包

## 包结构
| 包路径 | 说明 |
|---|---|
| `{package}.{biz}.repository` | {Name}Repository @Component（具体类，非端口实现） |
| `{package}.{biz}.dao` | {Name}Dao extends Mapper<{Name}DO> @RouterMapper |
| `{package}.{biz}.data` | {Name}DO @Table @Data |
| `{package}.{biz}.messaging` | {Name}MessageProducer @Component |
| `{package}.{biz}.types` | 值对象（{Name}Id / 枚举 / *Condition / *Message 等） |
| `{package}.datasource.{config,builder,scanner}` | 多数据源配置与扫描 |

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| Repository（具体类） | `{Name}Repository @Component` | `OrderRepository` |
| DAO | `{Name}Dao extends Mapper<{Name}DO> @RouterMapper` | `OrderDao` |
| 数据对象 | `{Name}DO @Table @Data` | `OrderDO` |
| 消息生产者 | `{Name}MessageProducer @Component` | `OrderMessageProducer` |
| 查询条件 | `{Name}SearchQuery extends PageQuery` | `OrderSearchQuery` |
| 消息 | `{Name}Message record` | `OrderMessage` |
| 数据源配置 | `PrimaryDataSourceConfiguration`/`MybatisConfigBuilder` | — |

## 规则
- 【强制】`*Repository` 是具体 `@Component` 类（无 domain 端口接口），直接被 application `Module` 注入调用
- 【强制】Repository 可封装 DB 调用，也可封装二/三方服务调用（经 facade）
- 【强制】DO 字段用包装类型；时间字段 `gmtCreate`/`gmtModified` 为 `Date`；表必备 `id`/`gmt_create`/`gmt_modified`
- 【强制】Dao 继承 tk.mybatis `Mapper<{Name}DO>`，用 `@RouterMapper(dataSource=...)` 绑定数据源；非特殊场景禁手写 SQL，用 `Weekend` 条件；当 `Weekend` 形式不满足时，用 MyBatis 注解方式实现
- 【强制】数据源配置全部置于 `datasource.*`，不得渗透到分层包结构
- 【强制】查询条件 `{Name}SearchQuery`、消息 `{Name}Message` 放本层 `types` 包（无 domain 层可放）
- 【推荐】分页用 `PageHelper.startPage` + `PageInfo`
- 【参考】`DO` 兼具数据对象与轻量实体角色，业务校验可放 Repository
- 【强制】向缓存中持久化 object 对象时，不要直接使用 object 序列化，转成 json 字符串后，再存入缓存，读取时注意反向操作

## 示例
```java
@Component
public class InventoryRepository {

    @Resource
    private InventoryDao inventoryDao;

    public void save(InventoryDO inventoryDO) {
        Long itemId = inventoryDO.getItemId();
        Assert.notNull(itemId, "INVENTORY_SAVE_ITEM_NULL", "商品ID为空");
        
        int count;

        Optional<InventoryDO> optional = find(itemId);
        if (optional.isPresent()) {
            count = inventoryDao.updateByPrimaryKeySelective(inventoryDO);
        } else {
            count = inventoryDao.insertSelective(inventoryDO);
        }

        Assert.isTrue(count > 0, "INVENTORY_REPOSITORY_SAVE_ERROR", "保存库存失败");
    }

    public void remove(InventoryDO inventoryDO) {
        Weekend<InventoryDO> weekend = Weekend.of(InventoryDO.class);

        WeekendCriteria<InventoryDO, Object> where = weekend.weekendCriteria();
        where.andEqualTo(InventoryDO::getItemId, inventoryDO.getItemId());

        inventoryDao.deleteByExample(weekend);
    }

    public Optional<InventoryDO> find(long itemId) {
        return Optional.ofNullable(inventoryDao.selectByPrimaryKey(itemId));
    }
}
```

## 分页查询示例
```java
public PageInfo<UserStockDO> page(UserStockStatus status, String categoryCode, int page, int pageSize) {
    Weekend<UserStockDO> weekend = Weekend.of(UserStockDO.class);
    weekend.excludeProperties(UserStockDO::getAttributes);

    if (UserStockStatus.HOLDING == status) {
        weekend.orderBy(UserStockDO::getHoldingQuantity).desc();
    } else {
        weekend.orderBy(UserStockDO::getStrategyScore).desc();
    }

    WeekendCriteria<UserStockDO, Object> where = weekend.weekendCriteria();
    where.andEqualTo(UserStockDO::getStatus, status.name());

    if (StringUtils.isNotBlank(categoryCode)) {
        where.andEqualTo(UserStockDO::getCategoryCode, categoryCode);
    }

    PageHelper.startPage(page, pageSize);

    return new PageInfo<>(userStockDao.selectByExample(weekend));
}
```

## 手写SQL示例
```java
@RouterMapper(dataSource = PrimaryDataSourceConfiguration.DATA_SOURCE)
public interface UserStockDao extends Mapper<UserStockDO> {

    @Insert(
        {
            "INSERT INTO user_stock(item_id, status, gmt_create, gmt_modified) ",
            "VALUES (#{itemId}, #{status}, #{gmtCreate,jdbcType=TIMESTAMP}, #{gmtModified,jdbcType=TIMESTAMP})"
        }
    )
    // 需要返回自增主键时，加以下配置
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(UserStockDO userStockDO);

    @Update(
        {
            "UPDATE user_stock ",
            "SET status = #{status}, gmt_modified = #{gmtModified,jdbcType=TIMESTAMP} ",
            "WHERE id = #{id}"
        }
    )
    int updateById(UserStockDO userStockDO);

    @Select(
        {
            "SELECT id, item_id, status, gmt_create, gmt_modified ",
            "FROM user_stock ",
            "WHERE id = #{id}"
        }
    )
    UserStockDO selectById(long id);

    // 动态 SQL，使用 Provider（多条件可选查询，Weekend 无法满足时使用）
    @SelectProvider(type = UserStockSqlProvider.class, method = "selectByCondition")
    List<UserStockDO> selectByCondition(@Param("itemId") Long itemId, @Param("status") String status);

    class UserStockSqlProvider {

        public String selectByCondition(@Param("itemId") Long itemId, @Param("status") String status) {
            return new SQL() {
                {
                    SELECT("id, item_id, status, gmt_create, gmt_modified");
                    FROM("user_stock");

                    if (itemId != null) {
                        WHERE("item_id = #{itemId}");
                    }

                    if (status != null) {
                        WHERE("status = #{status}");
                    }

                    ORDER_BY("gmt_create DESC");
                }
            }.toString();
        }
    }
}
```

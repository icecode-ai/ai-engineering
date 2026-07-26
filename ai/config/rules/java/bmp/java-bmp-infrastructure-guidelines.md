# 中台架构 - infrastructure 基础设施层规范

## 职责
持久层/出站适配器：实现 domain 的 Repository 与消息接口；DB 访问（DAO/DO/Converter）；多数据源配置。可调用 facade 封装二/三方服务调用并转换为自己的领域

## 包结构
| 包路径 | 说明 |
|---|---|
| `{package}.{biz}.repository` | {Name}RepositoryImpl @Component implements {Name}Repository |
| `{package}.{biz}.dao` | {Name}Dao extends Mapper<{Name}DO> @RouterMapper |
| `{package}.{biz}.data` | {Name}DO @Table @Data |
| `{package}.{biz}.converter` | {Name}Converter @Mapper（Domain ↔ DO） |
| `{package}.{biz}.messaging` | {Name}MessageProducerImpl @Component |
| `{package}.common.converter` | PageConverter（分页 DO ↔ Domain） |
| `{package}.datasource.{config,builder,scanner}` | 多数据源配置与扫描 |

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| Repository 实现 | `{Name}RepositoryImpl @Component` | `OrderRepositoryImpl` |
| Dao | `{Name}Dao extends Mapper<{Name}DO> @RouterMapper` | `OrderDao` |
| 数据对象 | `{Name}DO @Table @Data` | `OrderDO` |
| 转换器 | `{Name}Converter @Mapper` | `OrderConverter` |
| 消息实现 | `{Name}MessageProducerImpl @Component` | `OrderMessageProducerImpl` |
| 数据源配置 | `PrimaryDataSourceConfiguration`/`MybatisConfigBuilder` | — |

## 规则
- 【强制】`{Name}RepositoryImpl` 与 domain 接口 `{Name}Repository` 同包名（不同模块），实现接口
- 【强制】Repository 封装 DB 调用，也可封装二/三方服务调用（经 facade），转换为自己的领域
- 【强制】DO 字段用包装类型；时间字段 `gmtCreate`/`gmtModified` 为 `Date`；表必备 `id`/`gmt_create`/`gmt_modified`
- 【强制】DAO 继承 tk.mybatis `Mapper<{Name}DO>`，用 `@RouterMapper(dataSource=...)` 绑定数据源；非特殊场景禁手写 SQL，用 `Weekend` 条件；当 `Weekend` 形式不满足时，用 MyBatis 注解方式实现
- 【强制】Domain↔DO 转换用 MapStruct `{Name}Converter`，JSON 列用 `default` 方法 + FastJSON2 处理
- 【强制】数据源配置全部置于 `datasource.*`，不得渗透到领域分层包结构
- 【推荐】分页用 `PageHelper.startPage` + `PageInfo`
- 【推荐】弱依赖调用 try-catch 转 `SysException`
- 【强制】{Name}RepositoryImpl 内不使用私有静态方法组装参数，统一用 Converter，保证流程清晰

## 示例
```java
@Component
public class InventoryRepositoryImpl implements InventoryRepository {

    @Resource
    private InventoryDao inventoryDao;

    @Override
    public void save(Inventory inventory) {
        InventoryDO inventoryDO = InventoryConverter.INSTANCE.to(inventory);

        int count;

        Optional<Inventory> optional = find(inventory.getItemId());
        if (optional.isPresent()) {
            count = inventoryDao.updateByPrimaryKeySelective(inventoryDO);
        } else {
            count = inventoryDao.insertSelective(inventoryDO);
        }

        Assert.isTrue(count > 0, "保存库存失败");
    }

    @Override
    public void remove(Inventory aggregate) {
        Weekend<InventoryDO> weekend = Weekend.of(InventoryDO.class);

        WeekendCriteria<InventoryDO, Object> where = weekend.weekendCriteria();
        where.andEqualTo(InventoryDO::getItemId, aggregate.getItemId().value());

        inventoryDao.deleteByExample(weekend);
    }

    @Override
    public Optional<Inventory> find(ItemId itemId) {
        InventoryDO inventoryDO = inventoryDao.selectByPrimaryKey(itemId.value());
        if (Objects.isNull(inventoryDO)) {
            return Optional.empty();
        }

        return Optional.of(InventoryConverter.INSTANCE.from(inventoryDO));
    }
}
```

## 手写SQL示例
```java
@RouterMapper(dataSource = PrimaryDataSourceConfiguration.DATA_SOURCE)
public interface UserStockDao extends Mapper<UserStockDO> {

    @Insert(
        {
            "INSERT INTO user_stock(id, role_name, enabled, create_by, create_time) ",
            "VALUES (#{id},#{roleName},#{enabled},#{createBy},#{createTime,jdbcType=TIMESTAMP})"
        }
    )
    // 需要返回自增主键时，加以下配置
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int insert(UserStockDO userStockDO);

    @Update(
        {
            "UPDATE user_stock ",
            "SET role_name = #{roleName},enabled = #{enabled},create_by=#{createBy} ",
            "WHERE id=#{id}"
        }
    )
    int updateById(UserStockDO userStockDO);

    @Select(
        {
            "SELECT id,role_name roleName,enabled,create_by createBy,create_time createTime ",
            "FROM user_stock ",
            "WHERE id = #{id}"
        }
    )
    UserStockDO selectById(long id);
    
    // 动态 SQL，使用 Provider
    @SelectProvider(type = UserStockSqlProvider.class, method = "selectById")
    UserStockDO selectById(Long id);

    class UserStockSqlProvider {

        public String selectById(final Long id) {
            return new SQL() {
                {
                    SELECT("id,privilege_name,privilege_url");
                    FROM("user_stock");

                    if (id != null) {
                        WHERE("id = #{id}");
                    }
                }
            }.toString();
        }
    }
}
```

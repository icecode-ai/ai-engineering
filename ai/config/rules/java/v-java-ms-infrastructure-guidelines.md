# 微服务 - infrastructure 基础设施层规范

## 职责
持久层/出站适配器：DB 访问（Repository 具体类/DAO/DO）、消息生产者、多数据源配置。可调用 facade 封装二/三方服务调用。与 DDD/BMP 的区别：**`*Repository` 为具体 `@Component` 类（非端口接口实现）**，查询条件/消息类型也放在本层 `types` 包。

## 包结构
```
{package}.{biz}.
  repository     {Name}Repository @Component（具体类，非端口实现）
  dao            {Name}Dao extends Mapper<{Name}DO> @RouterMapper
  data           {Name}DO @Table @Data
  messaging      {Name}MessageProducer @Component
  types          {Name}SearchQuery extends PageQuery / {Name}Message record
datasource.{config,builder,scanner}   多数据源配置与扫描
```

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
- 【强制】`*Repository` 是具体 `@Component` 类（无 domain 端口接口），直接被 application `Module` 注入调用。
- 【强制】Repository 可封装 DB 调用，也可封装二/三方服务调用（经 facade）。
- 【强制】DO 字段用包装类型；时间字段 `gmtCreate`/`gmtModified` 为 `Date`；表必备 `id`/`gmt_create`/`gmt_modified`。
- 【强制】DAO 继承 tk.mybatis `Mapper<{Name}DO>`，用 `@RouterMapper(dataSource=...)` 绑定数据源，禁手写 SQL（用 `Weekend` 条件）。
- 【强制】数据源配置全部置于 `datasource.*`，不得渗透到分层包结构。
- 【强制】查询条件 `{Name}SearchQuery`、消息 `{Name}Message` 放本层 `types` 包（无 domain 层可放）。
- 【推荐】分页用 `PageHelper.startPage` + `PageInfo`。
- 【推荐】弱依赖调用 try-catch 转 `SysException`。
- 【参考】`DO` 兼具数据对象与轻量实体角色，业务校验可放 Repository。

## 依赖
- 可依赖：`facade`、`clean-spring-utils-starter`、tk.mybatis、PageHelper、Druid、MySQL、Lombok、FastJSON2
- 禁止：`application`、`interface`、`client`

## 示例
```java
@Component
public class OrderRepository {
    @Resource private OrderDao orderDao;
    @Resource private PartnerFacade partnerFacade;

    public void save(OrderDO order) {
        if (Objects.isNull(order.getOrderId())) {
            int id = orderDao.insertSelective(order);
            partnerFacade.syncOrder(id);
        } else {
            orderDao.updateByPrimaryKeySelective(order);
        }
    }

    public PageInfo<OrderDO> search(OrderSearchQuery query) {
        Weekend<OrderDO> weekend = Weekend.of(OrderDO.class);
        WeekendCriteria<OrderDO, Object> where = weekend.weekendCriteria();
        if (StringUtils.isNotBlank(query.getUserId())) {
            where.andEqualTo(OrderDO::getUserId, query.getUserId());
        }
        PageHelper.startPage(query.getPageIndex(), query.getPageSize(), query.isNeedTotalCount());
        return new PageInfo<>(orderDao.selectByExample(weekend));
    }
}
```

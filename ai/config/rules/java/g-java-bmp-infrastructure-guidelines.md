# 业务中台 - infrastructure 基础设施层规范

## 职责
持久层/出站适配器：实现 domain 的 Repository 与消息端口；DB 访问（DAO/DO/Converter）；多数据源配置。可调用 facade 封装二/三方服务调用并转换为自己的领域。

## 包结构
```
{package}.{biz}.
  repository     {Name}RepositoryImpl @Component implements {Name}Repository
  dao            {Name}Dao extends Mapper<{Name}DO> @RouterMapper
  data           {Name}DO @Table @Data
  converter      {Name}Converter @Mapper（Domain ↔ DO）
  messaging      {Name}MessageProducerImpl @Component
common.converter   PageConverter（分页 DO ↔ Domain）
datasource.{config,builder,scanner}   多数据源配置与扫描
```

## 命名约定
| 概念 | 命名 | 示例 |
|---|---|---|
| Repository 实现 | `{Name}RepositoryImpl @Component` | `OrderRepositoryImpl` |
| DAO | `{Name}Dao extends Mapper<{Name}DO> @RouterMapper` | `OrderDao` |
| 数据对象 | `{Name}DO @Table @Data` | `OrderDO` |
| 转换器 | `{Name}Converter @Mapper` | `OrderConverter` |
| 消息实现 | `{Name}MessageProducerImpl @Component` | `OrderMessageProducerImpl` |
| 数据源配置 | `PrimaryDataSourceConfiguration`/`MybatisConfigBuilder` | — |

## 规则
- 【强制】`{Name}RepositoryImpl` 与 domain 端口 `{Name}Repository` 同包名（不同模块），实现端口接口。
- 【强制】Repository 可封装 DB 调用，也可封装二/三方服务调用（经 facade），转换为自己的领域。
- 【强制】DO 字段用包装类型；时间字段 `gmtCreate`/`gmtModified` 为 `Date`；表必备 `id`/`gmt_create`/`gmt_modified`。
- 【强制】DAO 继承 tk.mybatis `Mapper<{Name}DO>`，用 `@RouterMapper(dataSource=...)` 绑定数据源，禁手写 SQL（用 `Weekend` 条件）。
- 【强制】Domain↔DO 转换用 MapStruct `{Name}Converter`，JSON 列用 `default` 方法 + FastJSON2 处理。
- 【强制】数据源配置全部置于 `datasource.*`，不得渗透到领域分层包结构。
- 【推荐】分页用 `PageHelper.startPage` + `PageInfo`。
- 【推荐】弱依赖调用 try-catch 转 `SysException`。

## 依赖
- 可依赖：`domain`、`facade`、`clean-spring-utils-starter`、tk.mybatis、PageHelper、Druid、MySQL、MapStruct、Lombok、FastJSON2
- 禁止：`application`、`interface`、`client`、`extension-apps`

## 示例
```java
@Component
public class OrderRepositoryImpl implements OrderRepository {
    @Resource private OrderDao orderDao;
    @Resource private PartnerFacade partnerFacade;

    public void save(Order order) {
        OrderDO orderDO = OrderConverter.INSTANCE.to(order);
        orderDao.insertSelective(orderDO);
        partnerFacade.syncOrder(orderDO.getOrderId());
    }
}
```

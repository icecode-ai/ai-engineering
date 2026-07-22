package com.sample.clean.datasource.scanner;

import java.lang.annotation.*;

/**
 * 数据源路由
 *
 * <p>多数据源场景，方便DAO与数据源之间的映射关系，以及保障数据源配置不影响领域分层结构</p>
 *
 * @author jim
 * @date 2013-05-21
 */
@Documented
@Inherited
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD, ElementType.FIELD, ElementType.PARAMETER})
public @interface RouterMapper {

    String dataSource() default "dataSource";
}

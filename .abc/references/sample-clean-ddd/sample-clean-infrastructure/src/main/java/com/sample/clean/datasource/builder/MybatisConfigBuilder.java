package com.sample.clean.datasource.builder;

import com.github.pagehelper.PageInterceptor;
import com.sample.clean.datasource.scanner.RouterMapper;
import com.sample.clean.datasource.scanner.RouterMapperScannerConfigurer;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.session.Configuration;
import org.mybatis.spring.SqlSessionFactoryBean;
import tk.mybatis.mapper.code.Style;
import tk.mybatis.mapper.entity.Config;
import tk.mybatis.mapper.mapperhelper.MapperHelper;

import javax.sql.DataSource;
import java.util.Properties;

/**
 * Mybatis 配置创建器
 *
 * @author jim
 * @date 2013-05-21
 */
public class MybatisConfigBuilder {

    public static SqlSessionFactoryBean buildMySqlSessionFactoryBean(
        DataSource dataSource,
        Configuration configuration
    ) {
        configuration.setMapUnderscoreToCamelCase(true);

        Properties properties = new Properties();
        properties.setProperty("dialect", "com.github.pagehelper.PageHelper");
        properties.setProperty("helperDialect", "mysql");
        properties.setProperty("reasonable", "false");
        properties.setProperty("supportMethodsArguments", "true");
        properties.setProperty("params", "count=countSql");

        PageInterceptor pageInterceptor = new PageInterceptor();
        pageInterceptor.setProperties(properties);

        SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(dataSource);
        sessionFactory.setTypeAliasesPackage("com.sample.clean.**.data");
        sessionFactory.setPlugins(new Interceptor[]{pageInterceptor});
        sessionFactory.setConfiguration(configuration);

        return sessionFactory;
    }

    public static RouterMapperScannerConfigurer buildMysqlRouterMapperScannerConfigurer(
        String sqlSessionFactoryBeanName,
        String dataSourceBeanName
    ) {
        Config config = new Config();
        config.setIdentity("MYSQL");
        config.setStyle(Style.camelhumpAndLowercase);

        MapperHelper mapperHelper = new MapperHelper();
        mapperHelper.setConfig(config);

        RouterMapperScannerConfigurer configurer = new RouterMapperScannerConfigurer();
        configurer.setAnnotationClass(RouterMapper.class);
        configurer.setSqlSessionFactoryBeanName(sqlSessionFactoryBeanName);
        configurer.setDataSourceBeanName(dataSourceBeanName);
        configurer.setBasePackage("com.sample.clean.**.dao");
        configurer.setMapperHelper(mapperHelper);

        return configurer;
    }
}

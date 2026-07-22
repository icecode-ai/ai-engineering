package com.sample.clean.datasource.config;

import com.alibaba.druid.pool.DruidDataSource;
import com.sample.clean.datasource.builder.MybatisConfigBuilder;
import com.sample.clean.datasource.scanner.RouterMapperScannerConfigurer;
import org.apache.ibatis.session.Configuration;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;

import javax.sql.DataSource;
import java.util.Properties;

/**
 * 主数据源配置
 *
 * @author jim
 * @date 2013-05-21
 */
@org.springframework.context.annotation.Configuration(proxyBeanMethods = false)
public class PrimaryDataSourceConfiguration {

    public static final String DATA_SOURCE = "dataSource";

    public static final String SESSION_FACTORY = "sessionFactory";

    public static final String MYBATIS_CONFIGURATION = "mybatisConfiguration";

    public static final String MAPPER_SCANNER = "routerMapperScannerConfigurer";

    public static final String TRANSACTION_MANAGER = "transactionManager";

    @Bean(name = DATA_SOURCE, initMethod = "init")
    @Primary
    public DataSource dataSource(Environment env) {
        Properties properties = Binder.get(env).bind("spring.datasource.primary", Properties.class).get();

        DruidDataSource dataSource = new DruidDataSource();
        dataSource.configFromProperties(properties);

        return dataSource;
    }

    @Bean(name = MYBATIS_CONFIGURATION)
    @ConfigurationProperties(prefix = "mybatis.configuration")
    @Primary
    public Configuration mybatisConfiguration() {
        return new Configuration();
    }

    @Bean(name = SESSION_FACTORY)
    @Primary
    public SqlSessionFactoryBean sessionFactory(
        @Qualifier(DATA_SOURCE) DataSource dataSource,
        @Qualifier(MYBATIS_CONFIGURATION) Configuration configuration
    ) {
        return MybatisConfigBuilder.buildMySqlSessionFactoryBean(dataSource, configuration);
    }

    @Bean(name = MAPPER_SCANNER)
    @Primary
    public static RouterMapperScannerConfigurer routerMapperScannerConfigurer() {
        return MybatisConfigBuilder.buildMysqlRouterMapperScannerConfigurer(SESSION_FACTORY, DATA_SOURCE);
    }

    @Bean(name = TRANSACTION_MANAGER)
    @Primary
    public DataSourceTransactionManager transactionManager(@Qualifier(DATA_SOURCE) DataSource dataSource) {
        DataSourceTransactionManager transactionManager = new DataSourceTransactionManager();
        transactionManager.setDataSource(dataSource);

        return transactionManager;
    }
}

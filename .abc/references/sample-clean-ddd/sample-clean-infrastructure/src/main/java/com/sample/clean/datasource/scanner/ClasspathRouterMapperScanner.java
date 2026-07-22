package com.sample.clean.datasource.scanner;

import org.springframework.beans.factory.annotation.AnnotatedBeanDefinition;
import org.springframework.beans.factory.support.BeanDefinitionRegistry;
import org.springframework.core.env.Environment;
import org.springframework.core.type.AnnotationMetadata;
import tk.mybatis.spring.mapper.ClassPathMapperScanner;

import java.util.Map;
import java.util.Objects;

/**
 * 数据源与DAO扫描绑定
 *
 * <p>多数据源场景，方便DAO与数据源之间的映射关系，以及保障数据源配置不影响领域分层结构</p>
 *
 * @author jim
 * @date 2013-05-21
 */
public class ClasspathRouterMapperScanner extends ClassPathMapperScanner {

    private String dataSourceBeanName;

    public ClasspathRouterMapperScanner(BeanDefinitionRegistry registry, Environment environment) {
        super(registry, environment);
    }

    public String getDataSourceBeanName() {
        return dataSourceBeanName;
    }

    public void setDataSourceBeanName(String dataSourceBeanName) {
        this.dataSourceBeanName = dataSourceBeanName;
    }

    @Override
    protected boolean isCandidateComponent(AnnotatedBeanDefinition beanDefinition) {
        boolean candidateComponent = super.isCandidateComponent(beanDefinition);
        if (!candidateComponent) {
            return false;
        }

        AnnotationMetadata metadata = beanDefinition.getMetadata();

        Map<String, Object> annotationAttributes = metadata.getAnnotationAttributes(RouterMapper.class.getName());
        if (Objects.isNull(annotationAttributes) || annotationAttributes.isEmpty()) {
            return false;
        }

        Object dataSource = annotationAttributes.get("dataSource");
        if (Objects.isNull(dataSource)) {
            return false;
        }

        return Objects.equals(dataSourceBeanName, String.valueOf(dataSource));
    }
}

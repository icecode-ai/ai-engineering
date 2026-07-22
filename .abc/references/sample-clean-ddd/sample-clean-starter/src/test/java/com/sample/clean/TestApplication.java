package com.sample.clean;

import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.PropertySource;
import org.springframework.test.context.ActiveProfiles;

/**
 * TestApplication
 *
 * @author jim
 * @date 2013-05-21
 */
@SpringBootApplication
@PropertySource(value = {"classpath:test.properties"})
@ActiveProfiles("testing")
public class TestApplication {}
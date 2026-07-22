package com.sample.clean.generator;

import java.io.IOException;

/**
 * CodeGeneratorTest
 *
 * @author jim
 * @date 2013-05-21
 */
public class CodeGeneratorTest {

    public static void main(String[] args) throws IOException {
        CodeTemplateGenerator.generate();

        CodeGenerator generator = new CodeGenerator("com.icecode.demo", "demo", "21", "21", "21", "0.0.1");

        generator.generate();
    }
}

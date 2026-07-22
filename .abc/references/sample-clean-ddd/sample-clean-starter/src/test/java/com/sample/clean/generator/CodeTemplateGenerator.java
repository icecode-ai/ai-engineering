package com.sample.clean.generator;

import com.google.common.collect.Lists;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;

import java.io.File;
import java.io.IOException;
import java.util.Collection;
import java.util.List;

/**
 * CodeTemplateGenerator
 *
 * @author jim
 * @date 2013-05-21
 */
public class CodeTemplateGenerator {

    public static final List<String> IGNORE_FINE_NAMES = Lists.newArrayList(".git", ".idea");

    public static void generate() throws IOException {
        String currentPath = CodeTemplateGenerator.class.getProtectionDomain().getCodeSource().getLocation().getFile();
        File currentDir = new File(currentPath);

        File objectDir = currentDir.getParentFile().getParentFile().getParentFile();

        String targetPath = currentDir.getParentFile().getParentFile().getPath()
            + File.separator
            + "target"
            + File.separator
            + objectDir.getName();

        File targetDir = new File(targetPath);
        FileUtils.deleteQuietly(targetDir);
        FileUtils.forceMkdir(targetDir);

        File[] objectFiles = objectDir.listFiles();
        for (File objectFile : objectFiles) {

            if (IGNORE_FINE_NAMES.contains(objectFile.getName())) {
                continue;
            }

            if (objectFile.getName().endsWith("pom.xml")) {
                generateObjectPom(targetDir, objectFile);
            } else if (objectFile.isFile()) {
                FileUtils.copyFileToDirectory(objectFile, targetDir);
            } else {
                generateModule(objectDir, targetDir, objectFile);
            }
        }
    }

    private static void generateObjectPom(File targetDir, File pom) throws IOException {
        FileUtils.copyFileToDirectory(pom, targetDir);

        String targetFilePath = targetDir + File.separator + pom.getName();
        File targetFile = new File(targetFilePath);
        assert targetFile.exists();

        List<String> lines = FileUtils.readLines(targetFile, "UTF-8");
        List<String> newLines = Lists.newArrayList();
        for (String line : lines) {
            String newLine = line.replaceAll("com\\.sample\\.clean", CodeGenerator.PLACEHOLDER_GROUP_ID);
            newLine = newLine.replaceAll("sample-clean", CodeGenerator.PLACEHOLDER_ARTIFACT_ID);
            newLine = newLine.replaceAll(
                "<maven.compiler.source>.*?</maven.compiler.source>",
                "<maven.compiler.source>" + CodeGenerator.PLACEHOLDER_PROJECT_JAVA_VERSION + "</maven.compiler.source>"
            );
            newLine = newLine.replaceAll(
                "<maven.compiler.target>.*?</maven.compiler.target>",
                "<maven.compiler.target>" + CodeGenerator.PLACEHOLDER_PROJECT_JAVA_VERSION + "</maven.compiler.target>"
            );
            newLine = newLine.replaceAll(
                "<java.version>.*?</java.version>",
                "<java.version>" + CodeGenerator.PLACEHOLDER_PROJECT_JAVA_VERSION + "</java.version>"
            );
            newLine = newLine.replaceAll(
                "<version.clean-dependencies>.*?</version.clean-dependencies>",
                "<version.clean-dependencies>"
                    + CodeGenerator.PLACEHOLDER_CLEAN_VERSION
                    + "</version.clean-dependencies>"
            );

            newLines.add(newLine);
        }

        FileUtils.writeLines(targetFile, "UTF-8", newLines, false);
    }

    private static void generateModule(File objectDir, File targetDir, File module) throws IOException {
        Collection<File> files = FileUtils.listFiles(module, new String[]{"java", "xml", "properties"}, true);
        for (File file : files) {
            String path = file.getPath();
            if (path.contains("target") || path.contains("generator") || path.contains("src/test/resources/"
                + objectDir.getName())) {
                continue;
            }

            if (file.getName().equals("pom.xml")) {
                generateModulePom(objectDir, targetDir, module, file);
            } else if (file.getName().equals("logback-spring.xml")) {
                generateLogback(objectDir, targetDir, module, file);
            } else if (file.getName().equals("application.properties")) {
                generateProperties(objectDir, targetDir, module, file);
            } else if (file.getName().endsWith(".java")) {
                generateJava(objectDir, targetDir, module, file);
            } else {
                copyFIle(objectDir, targetDir, file);
            }
        }
    }

    private static void generateModulePom(File objectDir, File targetDir, File module, File pom) throws IOException {
        File file = copyFIle(objectDir, targetDir, pom);

        List<String> lines = FileUtils.readLines(file, "UTF-8");
        List<String> newLines = Lists.newArrayList();
        for (String line : lines) {
            String newLine = line.replaceAll("com\\.sample\\.clean", CodeGenerator.PLACEHOLDER_GROUP_ID);
            newLine = newLine.replaceAll("sample-clean", CodeGenerator.PLACEHOLDER_ARTIFACT_ID);

            if (module.getName().equals("sample-clean-client")) {

            } else {
                newLine = newLine.replaceAll(
                    "<maven.compiler.source>.*?</maven.compiler.source>",
                    "<maven.compiler.source>"
                        + CodeGenerator.PLACEHOLDER_PROJECT_JAVA_VERSION
                        + "</maven.compiler.source>"
                );
                newLine = newLine.replaceAll(
                    "<maven.compiler.target>.*?</maven.compiler.target>",
                    "<maven.compiler.target>"
                        + CodeGenerator.PLACEHOLDER_PROJECT_JAVA_VERSION
                        + "</maven.compiler.target>"
                );
                newLine = newLine.replaceAll(
                    "<java.version>.*?</java.version>",
                    "<java.version>" + CodeGenerator.PLACEHOLDER_PROJECT_JAVA_VERSION + "</java.version>"
                );
            }

            newLines.add(newLine);
        }

        FileUtils.writeLines(file, "UTF-8", newLines, false);
    }

    private static void generateLogback(File objectDir, File targetDir, File module, File logback) throws IOException {
        File file = copyFIle(objectDir, targetDir, logback);

        List<String> lines = FileUtils.readLines(file, "UTF-8");
        List<String> newLines = Lists.newArrayList();
        for (String line : lines) {
            String newLine = line.replaceAll("sample-clean", CodeGenerator.PLACEHOLDER_ARTIFACT_ID);

            newLines.add(newLine);
        }

        FileUtils.writeLines(file, "UTF-8", newLines, false);
    }

    private static void generateProperties(File objectDir, File targetDir, File module, File properties)
    throws IOException {
        File file = copyFIle(objectDir, targetDir, properties);

        List<String> lines = FileUtils.readLines(file, "UTF-8");
        List<String> newLines = Lists.newArrayList();
        for (String line : lines) {
            String newLine = line.replaceAll("com\\.sample\\.clean", CodeGenerator.PLACEHOLDER_GROUP_ID);
            newLine = newLine.replaceAll("sample-clean", CodeGenerator.PLACEHOLDER_ARTIFACT_ID);

            newLines.add(newLine);
        }

        FileUtils.writeLines(file, "UTF-8", newLines, false);
    }

    private static void generateJava(File objectDir, File targetDir, File module, File java) throws IOException {
        File file = copyFIle(objectDir, targetDir, java);

        List<String> lines = FileUtils.readLines(file, "UTF-8");
        List<String> newLines = Lists.newArrayList();
        for (String line : lines) {
            String newLine = line.replaceAll("com\\.sample\\.clean", CodeGenerator.PLACEHOLDER_GROUP_ID);
            newLine = newLine.replaceAll("sample-clean", CodeGenerator.PLACEHOLDER_ARTIFACT_ID);

            newLines.add(newLine);
        }

        FileUtils.writeLines(file, "UTF-8", newLines, false);
    }

    private static File copyFIle(File objectDir, File targetDir, File file) throws IOException {
        assert objectDir.isFile();

        String relativeDir = StringUtils.removeStart(file.getParent(), objectDir.getPath());
        relativeDir = relativeDir.replaceAll("sample-clean", CodeGenerator.PLACEHOLDER_ARTIFACT_ID);
        relativeDir = relativeDir.replaceAll("com/sample/clean", CodeGenerator.PLACEHOLDER_GROUP_ID);

        String targetDirPath = targetDir.getPath() + relativeDir;
        FileUtils.copyFileToDirectory(file, new File(targetDirPath));

        String targetFilePath = targetDirPath + File.separator + file.getName();
        File targetFile = new File(targetFilePath);
        assert targetFile.exists();

        return targetFile;
    }
}

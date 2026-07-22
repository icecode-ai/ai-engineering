package com.sample.clean.generator;

import lombok.AllArgsConstructor;
import lombok.Data;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * CodeGenerator
 *
 * @author jim
 * @date 2013-05-21
 */
@AllArgsConstructor
@Data
public class CodeGenerator {

    public static final String PLACEHOLDER_GROUP_ID = "@_groupId_@";

    public static final String PLACEHOLDER_ARTIFACT_ID = "@_artifactId_@";

    public static final String PLACEHOLDER_PROJECT_JAVA_VERSION = "@_projectJavaVersion_@";

    public static final String PLACEHOLDER_CLIENT_JAVA_VERSION = "@_clientJavaVersion_@";

    public static final String PLACEHOLDER_CLIENT_RELEASE_VERSION = "@_clientReleaseVersion_@";

    public static final String PLACEHOLDER_CLEAN_VERSION = "@_cleanVersion_@";

    private final String groupId;

    private final String artifactId;

    private final String projectJavaVersion;

    private final String clientJavaVersion;

    private final String clientReleaseVersion;

    private final String cleanVersion;

    public File generate() throws IOException {
        String currentPath = CodeGenerator.class.getProtectionDomain().getCodeSource().getLocation().getFile();
        File currentDir = new File(currentPath);

        File objectDir = currentDir.getParentFile().getParentFile().getParentFile();

        String templatePath = currentDir.getParentFile().getParentFile().getPath()
            + File.separator
            + "target"
            + File.separator
            + objectDir.getName();

        File templateDir = new File(templatePath);

        String targetPath = System.getProperty("user.home")
            + File.separator
            + "Downloads"
            + File.separator
            + artifactId;
        File targetDir = new File(targetPath);
        FileUtils.deleteDirectory(targetDir);

        Collection<File> templateFiles = FileUtils.listFiles(
            templateDir,
            new String[]{"java", "xml", "properties", "gitignore", "sh"},
            true
        );

        for (File templateFile : templateFiles) {
            String relativePath = StringUtils.removeStart(templateFile.getPath(), templateDir.getPath());
            relativePath = StringUtils.removeEnd(relativePath, templateFile.getName());
            relativePath = relativePath.replaceAll(PLACEHOLDER_GROUP_ID, groupId.replaceAll("\\.", File.separator));
            relativePath = relativePath.replaceAll(PLACEHOLDER_ARTIFACT_ID, artifactId);

            String fileDirPath = targetPath + relativePath;
            File fileDir = new File(fileDirPath);

            FileUtils.copyFileToDirectory(templateFile, fileDir);

            File file = new File(fileDirPath + templateFile.getName());
            assert file.exists();

            List<String> lines = FileUtils.readLines(file, "UTF-8");
            List<String> newLines = new ArrayList<>(lines.size());
            for (String line : lines) {
                String newLine = line.replaceAll(PLACEHOLDER_GROUP_ID, groupId);
                newLine = newLine.replaceAll(PLACEHOLDER_ARTIFACT_ID, artifactId);
                newLine = newLine.replaceAll(PLACEHOLDER_PROJECT_JAVA_VERSION, projectJavaVersion);
                newLine = newLine.replaceAll(PLACEHOLDER_CLIENT_JAVA_VERSION, clientJavaVersion);
                newLine = newLine.replaceAll(PLACEHOLDER_CLIENT_RELEASE_VERSION, cleanVersion);
                newLine = newLine.replaceAll(PLACEHOLDER_CLEAN_VERSION, cleanVersion);

                newLines.add(newLine);
            }

            FileUtils.writeLines(file, newLines, false);
        }

        return targetDir;
    }

    private static File zip(File targetDir) throws IOException {
        // 1. 定义压缩后的文件路径
        String zipPath = targetDir.getAbsolutePath() + ".zip";
        File zipFile = new File(zipPath);

        // 2. 使用 Try-with-resources 自动关闭流
        try (
            FileOutputStream fos = new FileOutputStream(zipFile); BufferedOutputStream bos = new BufferedOutputStream(
            fos); ZipOutputStream zos = new ZipOutputStream(bos)
        ) {
            // 3. 获取要压缩的起始路径
            Path sourcePath = targetDir.toPath();

            // 4. 遍历文件夹
            Files.walkFileTree(
                sourcePath, new SimpleFileVisitor<Path>() {
                    @Override
                    public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
                        // 计算在压缩包内部的相对路径（文件夹需要以 / 结尾）
                        String relativePath = sourcePath.relativize(dir).toString();
                        if (!relativePath.isEmpty()) {
                            zos.putNextEntry(new ZipEntry(relativePath + "/"));
                            zos.closeEntry();
                        }
                        return FileVisitResult.CONTINUE;
                    }

                    @Override
                    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                        // 计算文件在压缩包内部的相对路径
                        String relativePath = sourcePath.relativize(file).toString();

                        // 创建一个压缩条目
                        zos.putNextEntry(new ZipEntry(relativePath));

                        // 将文件内容拷贝到压缩流中
                        Files.copy(file, zos);

                        zos.closeEntry();

                        return FileVisitResult.CONTINUE;
                    }
                }
            );
        }

        return zipFile;
    }
}

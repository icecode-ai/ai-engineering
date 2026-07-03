看下 `commands/ai-env-init.md` 中的 `cat > "$config_file" <<'EOF'` 部分，参考 `commands/ai-spec-propose.md` 中的的以下写法实现
```bash
{
     echo '## 1. <!-- Task Group Name -->'
     echo '- [ ] 1.1 <!-- Task description -->'
     echo '- [ ] 1.2 <!-- Task description -->'
     echo ''
     echo '## 2. <!-- Task Group Name -->'
     echo '- [ ] 2.1 <!-- Task description -->'
     echo '- [ ] 2.2 <!-- Task description -->'
} > "$change_dir/tasks.md"
```

另外看下 `commands` 目录下的指令内容中是否还有 `cat > xxx <<'xxx'` 写法，统一改掉

最后，检查下 `commands` 目录下的指令内容中的 `bash` 脚本，是否有错误的地方，是否有格式未对齐的地方，进行修复
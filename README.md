# Claude Code Windows 通知

在 Claude Code（VSCode 扩展）完成任务或需要你做选择时，自动弹出 Windows Toast 通知。

## 效果

| 触发场景 | 通知内容 |
|---------|---------|
| 任务完成（Stop hook） | 任务已完成，请查看结果 |
| 需要选择方案（AskUserQuestion） | 有方案需要你选择，请回到终端 |

## 文件说明

| 文件 | 说明 |
|------|------|
| `snoretoast.exe` | Windows Toast 通知命令行工具 |
| `claude-icon.png` | 通知图标 |
| `install.ps1` | 一键安装脚本 |

## 安装步骤

1. 将本仓库所有文件下载到同一目录（建议 `%USERPROFILE%\.claude\`）

2. 以**普通权限**运行安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

3. **重启 VSCode**（Claude Code 扩展需要重新加载配置）

4. 触发一次任务，验证通知是否弹出

## 工作原理

- 安装脚本自动注册 Windows AppUserModelId（`Claude.Code`），这是 Toast 通知的必要条件
- 在 `%USERPROFILE%\.claude\settings.json` 中写入两个 hook：
  - `Stop` hook：任务结束时触发
  - `PreToolUse` hook（匹配 `AskUserQuestion`）：Claude 需要你选择方案时触发
- hook 命令使用 PowerShell EncodedCommand，避免路径和编码问题
- 每条通知附带时间戳，防止 Windows 去重机制吞掉连续通知

## 注意事项

- 仅支持 **Windows 10/11**
- 需要 **PowerShell 5+**（系统自带）
- 通知依赖 Windows 操作中心，请确保通知功能已开启
- 若通知不弹出，检查"开始菜单"中是否有 `Claude Code` 快捷方式（安装脚本会自动创建）

## 卸载

删除 `%USERPROFILE%\.claude\settings.json` 中的 `hooks` 字段，或直接删除整个文件（Claude Code 会重新生成默认配置）。

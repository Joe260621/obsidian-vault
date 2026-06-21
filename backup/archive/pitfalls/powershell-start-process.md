# PowerShell Start-Process 与桌面快捷方式

> 最后更新: 2026-06-17

## 2026-06-14
- 问题: `Start-Process` 无法启动 npm 全局安装的 `.cmd` 包装脚本
- 原因: PowerShell `Start-Process` 需要真实 exe，不能直接跑 npm 全局的 .cmd 文件
- 解决: 改用 `node.exe` 直接运行 `dist/cli.js`，或使用 `.ps1` 脚本包装

## 2026-06-14
- 问题: 桌面快捷方式点击无反应
- 原因: CMD 批处理中文编码损坏；PowerShell 启动 .cmd 方式不对
- 解决: 换成 `.ps1` 脚本 + 快捷方式调用 `powershell.exe -File`
- 教训: Windows 下中文编码问题频发，优先用 UTF-8 编码的 .ps1 而非 .cmd；桌面快捷方式用 powershell.exe -File 是最可靠的方式
- 来源: daily/2026-06-14.md

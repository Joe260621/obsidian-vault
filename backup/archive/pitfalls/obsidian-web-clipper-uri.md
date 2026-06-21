# Obsidian Web Clipper URI 路径配置

> 最后更新: 2026-06-21

## 2026-06-20
- 问题: Web Clipper 修改保存路径时报 "Vault not found" 错误
- 原因: URI 协议（obsidian://web-clipper）需要的是 vault 名称（即 Obsidian 文件夹名），而不是完整文件系统路径
- 解决: 保持 clippings 默认路径，用「收」指令将剪藏自动归档到正确目录
- 教训: Obsidian URI 协议中的 vault 参数是逻辑名称而非物理路径，类似 notion:// 的设计
- 来源: daily/2026-06-20.md

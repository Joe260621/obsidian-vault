# Web Clipper 改路径报 Vault not found

> 最后更新: 2026-06-21

## 2026-06-20
- 问题: Web Clipper 修改默认保存路径时报 Vault not found
- 原因: URI 协议需要 vault 名称（即 Obsidian 文件夹名），而非完整文件路径
- 解决: 保持默认 clippings 路径，用「收」指令自动归档到目标位置
- 教训: Obsidian URI 协议以 vault 名称为寻址单位，配置文件路径时需用 vault 名而非绝对路径
- 来源: daily/2026-06-20.md

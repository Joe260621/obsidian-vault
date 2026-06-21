# Codex wire_api 迁移陷阱

> 最后更新: 2026-06-17

## 2026-06-14
- 问题: Codex v0.139.0 移除了 `wire_api = "chat"`，只保留 Responses API。DeepSeek 只支持 Chat Completions API，两者不兼容
- 原因: Codex 版本升级 breaking change，两种 API 协议不兼容
- 解决: 用 mimo2codex 做 Responses ↔ Chat Completions 协议翻译代理
- 教训: Codex 版本升级可能带来 breaking changes，需要关注 changelog；升级前先在测试环境验证
- 来源: daily/2026-06-14.md

## 2026-06-14
- 问题: DeepSeek 不识别 `developer` role（Codex Responses API 有此角色）
- 原因: DeepSeek Chat API 只支持 system/user/assistant
- 解决: mimo2codex 内置了角色映射（developer → system）
- 来源: daily/2026-06-14.md

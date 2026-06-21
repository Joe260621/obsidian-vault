# GitHub API 访问策略

> 最后更新: 2026-06-17

## 2026-06-14
- 发现: `api.github.com` 可正常访问，但 `github.com` 及其 CDN 被墙（443 端口封禁）。以后拉 GitHub 信息优先走 REST API
- 验证: 成功通过 API 获取 Glight release 信息和下载链接
- 限制: API 有 rate limit（60 req/h 未认证，5000 req/h 认证）
- 来源: daily/2026-06-14.md

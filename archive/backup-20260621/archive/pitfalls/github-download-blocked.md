# GitHub 下载被墙问题

> 最后更新: 2026-06-17

## 2026-06-14
- 问题: GitHub 下载全部超时（包括 Glight release、Obsidian 安装包等）
- 原因: 网络环境封禁 GitHub 443 端口（CDN 被墙），但 API 端点走不同 CDN 可访问
- 解决: 通过 `api.github.com` REST API 获取 release 信息和下载链接；对于无 API 覆盖的资源（如 Obsidian），需找国内镜像或离线安装包
- 教训: 区分 GitHub Web 前端和 API 端点的可达性；API 有 rate limit 但基本够用；关键软件需准备离线备份
- 来源: daily/2026-06-14.md

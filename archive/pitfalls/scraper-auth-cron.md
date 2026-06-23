# Scraper 认证 → Cron 无人值守不适用

> 最后更新: 2026-06-22

## 2026-06-22
- 问题: deepseek-usage-scraper.js 在 cron 定时任务中连续2天失败
- 原因: DeepSeek 平台需要浏览器登录认证（非 API Key），cron 无人值守环境下无法完成交互式登录
- 解决: 改用 cost-check.ps1（解析本地 Claude 会话 JSON）替代远程 scraping
- 教训: 需要 Web 登录认证的 scraper 不适合 cron 自动化。优先使用本地文件解析或 API Key 方案
- 来源: daily/2026-06-22.md

# Claude Code Cron 定时任务限制

> 最后更新: 2026-06-18

## 2026-06-18
- 问题: CronCreate 创建的 durable 定时任务，在电脑关机或 Claude Code 不运行时不会触发
- 原因: Cron 任务依赖 Claude Code REPL 处于运行且空闲状态；关机后进程不存在，无法执行
- 解决方案:
  - 短期: 保持电脑不关机 + 关闭自动睡眠 + Claude Code 前台运行
  - 长期: 云服务器运行 Claude Code（最可靠）或 Windows Task Scheduler 唤醒
- 教训: Claude Code cron 适用于"电脑开着时"的定时任务，不适合真正的无人值守自动化
- 来源: daily/2026-06-17.md（早晨自动化首次夜间测试）

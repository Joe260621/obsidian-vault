# Windows Update 自动重启打断服务

> 最后更新: 2026-06-19

## 2026-06-19
- 问题: Windows Update 22:08 安装 .NET Framework 补丁(KB5088864)后自动重启，导致所有后台服务（VSCode Claude Code、cron、proxy、cc-connect）中断
- 原因: Windows 10 默认「计划内重启」策略，有更新自动装完就重启
- 解决: 注册表禁用自动重启
  ```
  HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
  NoAutoRebootWithLoggedOnUsers = 1
  AUOptions = 2 (下载前通知)
  ```
- 教训: 24x7 运行的机器必须主动禁用 Windows Update 自动重启，不是关睡眠就够了
- 来源: daily/2026-06-18.md (cron 第二次夜间测试失败)

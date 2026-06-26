# 飞书双向管道掉线

> 最后更新: 2026-06-25

## 2026-06-25
- 问题: 飞书双向管道掉线，proxy + ngrok + task_runner 全部停止
- 原因: 三个组件各自独立运行，无统一启动脚本，掉线后无人重启
- 解决: 
  1. feishu_proxy.py 端口统一为 5681，去掉 replace 依赖
  2. startup.ps1 重写：一键启动所有组件 + 自动清理旧进程
  3. ngrok 固定 URL: `luckless-impaired-enclose.ngrok-free.app` → localhost:5681
  4. 重启命令: `cd D:/ProjectManagement/AI && .\startup.ps1`
- 教训: 多组件管道必须有统一启动入口；端口配置硬编码统一管理，避免跨文件 replace 依赖
- 来源: daily/2026-06-25.md

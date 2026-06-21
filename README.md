# 早晨自动化系统 — 部署包

## 这是什么

每天早上 8:35 自动：归档昨日 → 更新进度 → 提取知识 → 生成 TODO → 推送飞书。

## 部署步骤（3 步）

### 1. 复制文件

把包里所有文件复制到你的 Claude 项目根目录，保持目录结构不变。

### 2. 创建目录

在项目根目录新建两个空文件夹：
- `daily\`
- `archive\insights\`
- `archive\pitfalls\`

### 3. 创建定时任务

对 Claude Code 说：
> 使用 CronCreate 创建定时任务：cron "35 8 * * *"，durable true，recurring true，prompt 是"执行早晨例行程序。使用 Skill 工具加载 morning-routine 技能，严格按照 SKILL.md 中定义的 6 步流程执行：第1步发现昨日、第2步产出昨日摘要、第3步更新 progress.md、第4步提取知识到 archive/、第5步生成今日 daily 模板和 TODO.md、第6步调用 scripts/send-feishu.ps1 推送摘要到飞书。"

## 飞书配置

同一飞书账号，`send-feishu.ps1` 里的凭证无需修改，直接能用。

## 测试

对 Claude Code 说「跑早晨例行」，检查飞书是否收到推送。

## 注意

- Claude Code 需保持运行，关机后 cron 不触发
- 错过会自动追赶
- Cron 7 天过期，需续期

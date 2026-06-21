---
name: deepseek-token-optimization
description: "DeepSeek API token optimization — flash model default, session segmentation rules, cost monitoring"
metadata:
  type: project
  originSessionId: 254dd6ec-8123-40ff-93d7-e239662f4114
---

# DeepSeek Token 优化配置

## 环境变量
- `CLAUDE_CODE_ATTRIBUTION_HEADER=0` — 禁用 cch 参数注入，恢复请求前缀稳定性
  - 设置位置：`~/.bashrc` + User 级别环境变量 + `.env` 文件
  - 生效方式：重启终端后自动加载

## 模型路由
- CC Router 配置 (`C:\Users\YU\.claude-code-router\config.json`)：
  - 默认模型：`deepseek-v4-flash`（省 token）
  - 可用模型：`deepseek-chat`, `deepseek-reasoner`, `deepseek-v4-flash`, `deepseek-v4-pro`
  - **v4-pro 仅在复杂任务时显式切换**
- 切换方式：`/model` 命令或启动时指定

## 🔴 2026-06-20 成本暴增复盘

**单日消耗 CNY 32.56，历史最高。** 根因分析：

| 会话 | 轮次 | 缓存读取 | 费用 | 话题 |
|------|------|----------|------|------|
| 95f86268 | 1,073 | 1.9亿 | ¥22.25 | morning-routine 自动化、招聘监控 |
| a0d5dee0 | 726 | 1.16亿 | ¥14.05 | LLM Wiki、知识库、职业规划 |
| 其他 4 会话 | 512 | - | ¥5.38 | 日常任务 |

**费用构成**：缓存读取 80%、输出 12%、输入 8%

**核心原因**：
1. 两个超长会话（1073+726 轮）持续在同一个会话中头脑风暴
2. DeepSeek 每次对话需重读全部历史缓存，会话越长越贵（O(n²) 效应）
3. 128 条用户消息 × 1075 个助手轮次 = 每次返回都要为整个历史付费

## CLAUDE.md 成本控制规则（硬性）

已写入 `CLAUDE.md` 规则 15-20：

15. **会话分段**：超过 50 轮必须提议分段，产出结构化和接力文档
16. **话题切换必分段**：切换话题/项目必须封存旧话题 + 开新会话
17. **禁止裸 Continue**：用户说"继续"时必须先列出待做事项，请求明确指令
18. **头脑风暴分阶段**：探索→聚焦→决策→执行，每阶段 ≤50 轮
19. **成本自觉**：超过 3000 output tokens 时简短标注消耗估算
20. **长会话预警**：30+ 轮时主动提醒分段

## 监控脚本

- `.\claude\hooks\session-cost-check.ps1` — 会话成本分析（可手动调用）
- `.\claude\hooks\cost-check.ps1` — 今日所有会话汇总
- `.\claude\hooks\session-start.ps1` — SessionStart 时自动注入成本警告（≥30轮时）

## Scraper 改进
- `scripts/deepseek-usage-scraper.js`：
  - 按 "Tokens" 标签切分 API 和 Token 数据列
  - 过滤日期范围（6-1, 6-30）防止数字污染
  - 从 "API"/"请求" 关键词之后提取数字（避免模型名中的 v4 干扰）
  - 输出：Balance, Monthly Cost, Per-Model (total/today/yesterday), Daily Summary

## 消费现状 (2026-06-20)
- 余额：¥27.27（即将耗尽 → 已消耗 ¥32.56 今日）
- 6月累计：~25.7亿 tokens（v4-pro 占 99.87%）
- **优化后目标**：单日控制在 ¥10 以内
- 日均：~1.28亿 tokens

## 优化要点
- ⚠️ **最重要**：长会话分段（50 轮红线），单独此项可比今天省 ¥25+
- 简单任务（文件读写、搜索、bash）默认走 flash
- 复杂任务（多文件重构、架构设计）手动切 v4-pro
- 长对话及时总结压缩上下文
- 确定性操作（格式转换、数据处理）用代码脚本而非 LLM

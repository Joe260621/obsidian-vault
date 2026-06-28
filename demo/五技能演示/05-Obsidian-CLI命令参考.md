---
title: Obsidian CLI 命令参考
tags:
  - obsidian
  - cli
  - reference
created: 2026-06-29
---

# Obsidian CLI 命令参考

> [!note] 前置条件
> Obsidian CLI 内置在 Obsidian 桌面版 v1.8+，需要：
> 1. Obsidian 正在运行
> 2. 在设置中启用 **"命令行支持"**（设置 → 选项 → 编辑器 → 命令行支持）
> 3. 在终端输入 `obsidian help` 查看所有命令

## 常用命令

### 笔记操作

```bash
# 创建笔记
obsidian create name="My Note" content="# Hello" template="Template" silent

# 读取笔记
obsidian read file="My Note"

# 追加内容
obsidian append file="My Note" content="- [ ] 新任务"

# 搜索
obsidian search query="会员运营" limit=10
```

### 属性操作

```bash
# 设置属性
obsidian property:set name="status" value="done" file="My Note"

# 查看标签
obsidian tags sort=count

# 查看反向链接
obsidian backlinks file="求职分析笔记"
```

### 每日笔记

```bash
# 读取今日笔记
obsidian daily:read

# 追加任务
obsidian daily:append content="- [ ] 投递5家简历"
```

### 任务管理

```bash
# 查看今日待办
obsidian tasks daily
```

### 开发调试（写插件时用）

```bash
# 重载插件
obsidian plugin:reload id=my-plugin

# 查看错误
obsidian dev:errors

# 截图
obsidian dev:screenshot path=screenshot.png

# 执行JS
obsidian eval code="app.vault.getFiles().length"
```

> [!tip] 组合使用
> 配合 `--copy` 可将输出复制到剪贴板；加 `silent` 防止弹窗。
> 指定仓库：`obsidian vault="My Vault" search query="test"`

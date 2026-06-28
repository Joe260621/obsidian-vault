---
title: Obsidian × AI 五技能集成
tags:
  - claude
  - obsidian
  - setup
created: 2026-06-29
---

# Obsidian × AI 五技能集成

已安装 **kepano/obsidian-skills** 五技能，让 Claude AI 能读写 Obsidian 原生格式。

## 安装位置

| 路径 | 用途 |
|------|------|
| `D:\ProjectManagement\AI\.claude\skills\` | Claude 运行目录 |
| `D:\ProjectManagement\Claude\.claude\skills\` | Obsidian vault（双向同步） |

## 五技能一览

### 1. `obsidian-markdown` — Obsidian风味Markdown
- 双链 `[[Note Name|Display]]`
- 嵌入 `![[image.png|300]]`
- Callout `> [!warning] Title`
- 属性 frontmatter `tags:`, `aliases:`
- 高亮 `==text==`、评论 `%%text%%`
- LaTeX `$e=mc^2$`、Mermaid 图表
- 参考：`skills/obsidian-markdown/references/`

### 2. `json-canvas` — 思维导图 Canvas
- JSON Canvas 1.0 规范
- 四种节点：`text`、`file`、`link`、`group`
- 支持连线、箭头、颜色预设
- `.canvas` 文件可直接在 Obsidian 中打开
- 参考：`skills/json-canvas/references/EXAMPLES.md`

### 3. `obsidian-bases` — 数据库视图
- `.base` 文件 YAML 语法
- 四种视图：table、cards、list、map
- 过滤语法（and/or/not + 操作符）
- 公式：日期运算、条件逻辑、字符串格式化
- 参考：`skills/obsidian-bases/references/FUNCTIONS_REFERENCE.md`

### 4. `defuddle` — 网页剪藏
- 全局安装：`npm install -g defuddle`
- 用法：`defuddle parse <url> --md`
- 去广告、去导航，提取正文Markdown
- 替代 WebFetch 用于网页内容提取
- 配合 Omega Template 可一键剪藏到 vault

### 5. `obsidian-cli` — 命令行管理
- 需要 Obsidian 桌面版运行中
- 命令：`obsidian create`、`obsidian read`、`obsidian search`
- 插件开发：`obsidian plugin:reload`、`obsidian dev:errors`
- 每日笔记：`obsidian daily:read`、`obsidian daily:append`

## 使用场景

| 场景 | 用什么技能 |
|------|-----------|
| 写笔记、双链文章 | obsidian-markdown |
| 做思维导图/流程图 | json-canvas |
| 给笔记建表格视图 | obsidian-bases |
| 保存网页到 vault | defuddle |
| 搜索/创建/管理笔记 | obsidian-cli |

## 相关链接
- [kepano/obsidian-skills GitHub](https://github.com/kepano/obsidian-skills)
- [JSON Canvas Spec](https://jsoncanvas.org/spec/1.0/)
- [Defuddle](https://github.com/kepano/defuddle)
- [Obsidian Help - CLI](https://help.obsidian.md/cli)

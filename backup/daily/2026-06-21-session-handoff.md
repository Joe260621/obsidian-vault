# 会话接力文档 — 2026-06-21

> 状态：阶段一+二完成，准备进入阶段三。新电脑从这里接。

---

## 本次完成

| 事项 | 产出 | 位置 |
|------|------|------|
| 资料扫描 | 287 文件分类，34 垃圾跳过，253 入库 | `wiki/考编/_索引/` |
| 脏数据过滤 | 自动识别打印广告、加群图、重复封面 | `wiki/考编/_索引/_filter-report.md` |
| 文本提取 | 251 PDF → 310 万字符 | `wiki/考编/_extracted/` |
| OCR 高价值 | 36 个扫描件 → tesseract.js 中文识别 | `wiki/考编/_extracted/_ocr_results/` |
| 成本预估 | 阶段三约需 1.2M~3M token，分 30 个小会话 | `wiki/考编/_索引/_final-manifest.md` |

## 双仓库结构（重要）

- **Obsidian** (`G:\quark\Obsidian笔记\Clippings\`) = 原始资料（67GB，含视频）
- **Claude** (`G:\Claude\wiki\考编\`) = 提炼笔记 + 提取文本
  - `_索引/` — index.json + 过滤报告 + 最终清单
  - `_extracted/` — 251 个 .txt（纯文本提取结果）
  - `_extracted/_ocr_results/` — 36 个 OCR 结果 .txt
  - ⚠️ `_extracted/_ocr_pages/` — 2.4GB PNG 中间产物（备份已排除，可重新生成）

## 模块处理优先级

| # | 模块 | 文件 | 状态 |
|---|------|------|------|
| 1 | 数量关系（高照） | 17 课件 + 1 笔记 | ✅ 文本+OCR 就绪 |
| 2 | 资料分析（高照） | 4 讲义 | ✅ 纯文本就绪 |
| 3 | 判断推理（薛睿） | 16 讲义 | ✅ 纯文本就绪 |
| 4 | 图推 24 诀（薛睿） | 25 讲义 | ✅ 纯文本就绪 |
| 5 | 言语理解（大懒猫） | 10 笔记 + 1 题本 | ✅ OCR 就绪 |
| 6 | 行测真题 04-25 | 74 套 | ✅ 题目文本就绪，答案需 OCR |
| 7 | 申论真题 03-24 | 31 套 | ✅ 纯文本就绪 |
| 8 | 申论素材（菜头） | 17 课件 | ✅ 纯文本就绪 |
| 9 | 申论（忠政） | 11 文件 | ✅ 文本+OCR 就绪 |
| 10 | 政治常识+时政（小黑） | 42 文件 | ✅ 文本+OCR 就绪 |

## 阶段三启动指南

在新电脑上对 Claude 说：

> 「这是考编资料整理的接力任务。阶段一和阶段二已完成，资料索引在 wiki/考编/_索引/index.json，提取文本在 wiki/考编/_extracted/。
> 请先读 _索引/_final-manifest.md 了解全貌，然后按优先级从模块 1（数量关系）开始逐模块提炼。
> 每个模块控制在 3-4 个会话内，每个会话不超过 50 轮。
> 提炼模板：知识点→公式/方法→典型例题→易错点。
> 产出写入 wiki/考编/{模块名}/ 目录。」

## 关键脚本（可能需要在新电脑安装依赖）

| 脚本 | 用途 | 依赖 |
|------|------|------|
| `scripts/scan-clippings.py` | 扫描索引 | PyPDF2 |
| `scripts/phase2-extract.py` | 文本提取 | PyPDF2 |
| `scripts/ocr-pipeline.py` | PDF→PNG 渲染 | PyMuPDF (fitz) |
| `scripts/ocr-batch-v2.js` | tesseract OCR | tesseract.js |

安装命令：
```bash
pip install PyPDF2 PyMuPDF
npm install -g tesseract.js
```

## Obsidian 注意事项

如果新电脑上 Obsidian 仓库路径不同，需要修改脚本中 `CLIPPINGS` 变量（当前为 `G:\quark\Obsidian笔记\Clippings`）。Claude wiki 路径为相对路径，放在 Claude 项目目录下即可。

## 成本控制提醒

- DeepSeek 模型，每会话不超过 50 轮
- 阶段三每个模块 3-4 个会话
- 预估总量 1.2M~3M token
- 到 30 轮主动预警，到 50 轮强制分段

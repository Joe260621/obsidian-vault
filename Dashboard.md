---
cssclass: dashboard
---

# 🏠 项目管理仪表盘

> **`= date(today).year` 年 `= date(today).month` 月 `= date(today).day` 日** · `= dateformat(date(today), "EEEE")` · 2026 夏日规划

---

## 📊 数据概览

| 📥 待办任务 | 📅 Daily 笔记 | 📚 知识库 | ✂️ 剪藏 | 🧠 记忆库 |
|:-----------:|:------------:|:--------:|:------:|:--------:|
| `$= dv.pages().file.tasks.where(t => !t.completed).length` | `$= dv.pages('"daily"').length` | `$= dv.pages('"wiki"').length` | `$= dv.pages('"Clippings"').length` | `$= dv.pages('"memory"').length` |

---

## 🔧 快捷操作

```button
name 🆕 新建 Daily
type command
action Daily notes: Open today's daily note
```

```button
name ✅ 待办清单
type link
action TODO.md
```

```button
name 📋 项目进度
type link
action progress.md
```

```button
name 📖 CLAUDE.md
type link
action CLAUDE.md
```

```button
name 🎓 考编入口
type link
action wiki/考编/考编学习计划_阶段四.md
```

```button
name 📝 今日总结
type link
action daily/2026-06-22.md
```

```button
name 🔄 Git 同步
type command
action Obsidian Git: Create backup
```

```button
name 🗂️ 知识库
type link
action wiki/index.md
```

---

## 🧭 导航

| 🏠 [主页](Dashboard.md) | 📅 [Daily](daily/) | ✅ [待办](TODO.md) | 📚 [Wiki](wiki/index.md) |
|:---:|:---:|:---:|:---:|

---

## ⏰ 提醒

> **📌 海珠区社区招聘成绩发布** — `= (date("2026-06-24") - date(today)).days` 天后

```dataviewjs
const target = DateTime.fromISO("2026-06-24");
const now = DateTime.now();
const diff = target.diff(now, ["days", "hours"]);
dv.span(`⏳ 距离成绩发布还有 **${Math.floor(diff.days)} 天 ${Math.floor(diff.hours % 24)} 时**`);
```

---

## 🔴 优先处理

```dataview
TASK
FROM "TODO.md"
WHERE !completed AND contains(text, "⏰")
LIMIT 10
```

```dataview
TABLE file.ctime as "创建时间", file.mtime as "修改时间"
FROM "Clippings"
SORT file.ctime DESC
LIMIT 5
```

---

## 📝 最近修改

```dataview
TABLE file.mtime as "最后修改" 
FROM "" 
  AND -#template
  AND -"archive"
  AND -".obsidian"
  AND -"node_modules"
SORT file.mtime DESC 
LIMIT 10
```

---

## 📈 项目进度

```dataview
TASK
FROM "progress.md"
WHERE !completed
LIMIT 5
```

---

> 💡 点击上方按钮快速操作 · [[TODO.md|查看全部待办]] · [[progress.md|查看全部进度]] · [[2026-06-21-session-handoff.md|会话记录]]

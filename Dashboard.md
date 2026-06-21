---
cssclass: dashboard
---

```dataviewjs
// ⚡ 第一优先级：折叠侧边栏 + 移除属性面板 + 注入全屏背景
const app = dv.app;
app.workspace.leftSplit.collapse();
app.workspace.rightSplit.collapse();

setTimeout(() => {
  // 移除属性面板
  document.querySelectorAll('.metadata-container').forEach(m => m.remove());
  // 隐藏内联标题
  document.querySelectorAll('.inline-title').forEach(t => { if (t.textContent.trim() === 'Dashboard') t.style.display = 'none'; });
  // 给整个工作区上蓝天渐变背景（覆盖两边留白）
  const leaf = document.querySelector('.workspace-leaf-content');
  if (leaf) {
    leaf.style.background = 'linear-gradient(180deg, #dceefb 0%, #e8f2fc 15%, #f5f7fb 40%, #ffffff 80%)';
    leaf.style.backgroundAttachment = 'fixed';
  }
}, 100);
```

# 🏠 Home

```dataviewjs
const now = DateTime.now();
const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
const wd = weekdays[now.weekday - 1];
dv.paragraph('<center><b>' + now.toFormat('yyyy-MM-dd') + '</b> · ' + wd + ' · ' + now.toFormat('HH:mm') + ' · 2026·夏日每日规划</center>');
```

---

## 📊 概览

```dataviewjs
const app = dv.app;
const stats = [
  { icon: '📥', label: '待办任务', count: dv.pages().flatMap(p => p.file.tasks || []).where(t => !t.completed).length, link: 'TODO.md' },
  { icon: '📅', label: 'Daily 笔记', count: dv.pages('"daily"').length, link: 'daily/2026-06-22.md' },
  { icon: '📚', label: '知识库', count: dv.pages('"wiki"').length, link: 'wiki/index.md' },
  { icon: '✂️', label: '剪藏', count: dv.pages('"Clippings"').length, link: 'Clippings/' },
  { icon: '🧠', label: '记忆库', count: dv.pages('"memory"').length, link: 'memory/MEMORY.md' },
];

const row = dv.el('div', '', { cls: 'stats-row' });
stats.forEach(s => {
  const card = document.createElement('div');
  card.className = 'stats-card';
  card.innerHTML = '<span class="stats-icon">' + s.icon + '</span><span class="stats-label">' + s.label + '</span><span class="stats-num">' + s.count + '</span>';
  card.style.cursor = 'pointer';
  card.addEventListener('click', () => app.workspace.openLinkText(s.link, '', false));
  row.appendChild(card);
});
```

---

## 🎯 求职

```dataviewjs
const app = dv.app;
const box = dv.el('div', '', { cls: 'job-box' });
box.innerHTML = '<div class="job-title">🔴 求职进行中</div>' +
  '<div class="job-sub">广州 · 用户运营 / 私域运营</div>';
box.style.cursor = 'pointer';
box.addEventListener('click', () => app.workspace.openLinkText('求职入口.md', '', false));
```

```dataviewjs
const app = dv.app;
const btns = [
  { label: '📋 求职总览', action: () => app.workspace.openLinkText('求职入口.md', '', false) },
  { label: '📄 我的简历', action: () => app.workspace.openLinkText('raw/career/resume-zhuowenyu-user-operations.md', '', false) },
  { label: '💬 面试准备', action: () => app.workspace.openLinkText('wiki/career/私域运营面试真题解析.md', '', false) },
  { label: '🔍 岗位搜索', action: () => app.workspace.openLinkText('raw/career/2026-06-04-bosszhipin-user-operations-jobs.md', '', false) },
];

const row = dv.el('div', '', { cls: 'btn-row' });
btns.forEach(b => {
  const btn = document.createElement('button');
  btn.textContent = b.label;
  btn.className = 'dash-btn job-btn';
  btn.addEventListener('click', b.action);
  row.appendChild(btn);
});
```

---

## 🔧 功能栏

```dataviewjs
const app = dv.app;
const buttons = [
  { label: '🆕 新建 Daily', action: () => app.workspace.openLinkText('daily/2026-06-22.md', '', false) },
  { label: '📋 项目进度', action: () => app.workspace.openLinkText('progress.md', '', false) },
  { label: '✅ 待办任务', action: () => app.workspace.openLinkText('TODO.md', '', false) },
  { label: '📖 CLAUDE.md', action: () => app.workspace.openLinkText('CLAUDE.md', '', false) },
  { label: '🎓 考编入口', action: () => app.workspace.openLinkText('wiki/考编/考编学习计划_阶段四.md', '', false) },
  { label: '🗂️ 知识库', action: () => app.workspace.openLinkText('wiki/index.md', '', false) },
  { label: '🔄 Git 同步', action: () => { try { app.commands.executeCommandById('obsidian-git:create-backup'); } catch(e) { app.commands.executeCommandById('obsidian-git:commit'); } } },
  { label: '📝 今日总结', action: () => app.workspace.openLinkText('daily/2026-06-22.md', '', false) },
];

const row = dv.el('div', '', { cls: 'btn-row' });
buttons.forEach(b => {
  const btn = document.createElement('button');
  btn.textContent = b.label;
  btn.className = 'dash-btn';
  btn.addEventListener('click', b.action);
  row.appendChild(btn);
});
```

---

## 🧭 导航栏

| 🏠 主页 | 📅 Daily | ✅ 待办 | 📚 Wiki |
|:---:|:---:|:---:|:---:|
| [→](Dashboard.md) | [→](daily/) | [→](TODO.md) | [→](wiki/index.md) |

---

## ⏰ 提醒

```dataviewjs
const target = DateTime.fromISO('2026-06-24');
const now = DateTime.now();
const diff = target.diff(now, ['days', 'hours']);

const box = dv.el('div', '', { cls: 'reminder-box' });
box.innerHTML = '<div class="reminder-title">📌 海珠区社区招聘成绩发布</div>' +
  '<div class="reminder-countdown"><span class="reminder-num">' + Math.floor(diff.days) + '</span> 天 <span class="reminder-num">' + Math.floor(diff.hours % 24) + '</span> 时</div>' +
  '<div class="reminder-date">2026-06-24 00:00</div>';
```

---

## 🔴 优先处理

```dataview
TASK
FROM "TODO.md"
WHERE !completed
LIMIT 10
```

```dataview
TABLE file.ctime as "创建时间"
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
LIMIT 8
```

---

> 💡 点击功能栏按钮快速操作 · [查看全部待办](TODO.md) · [查看项目进度](progress.md)

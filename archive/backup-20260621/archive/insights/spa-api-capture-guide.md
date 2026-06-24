# SPA 站点 API 抓取指南

> 最后更新: 2026-06-18

## 原理

SPA 页面 HTML 是空壳，但数据通过 AJAX/Fetch 请求从 API 加载。F12 捕获 API URL 后，PowerShell 可直接调用。

## 步骤（夸克浏览器）

1. F12 打开开发者工具
2. 点 **Network** 标签
3. 点 **Fetch/XHR** 过滤器（只看数据接口）
4. 刷新页面 (F5)
5. 在请求列表中找 **Type 为 xhr/fetch**、**返回 JSON 数据** 的请求
6. 右键 → Copy → Copy link address
7. 把 URL 发给 Claude

## 各站点待抓取 API

| 站点 | 页面 URL | 目标数据 |
|------|----------|----------|
| 集思录 QDII | jisilu.cn/data/qdii/ | 基金溢价率表格 |
| 事招雷达 | qgsydw.com | 广州招聘公告 |
| 海珠区招聘 | hzsg2026.zhaopin.com/zk/ | 成绩公告 |
| Boss直聘 | zhipin.com/guangzhou/ | 运营岗位列表 |

## 来源
- daily/2026-06-18.md

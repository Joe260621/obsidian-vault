# JS 渲染页面爬取失败

> 最后更新: 2026-06-21

## 2026-06-20
- 问题: Bitcadet/Darkroom 爬不到文本内容
- 原因: Framer JS 渲染，静态 HTTP 请求拿不到动态内容
- 解决: 改用工作流已提取的声明数据做方向性参考
- 教训: JS 渲染页面需要 headless browser（Playwright/Puppeteer），纯 HTTP 爬虫无法获取动态内容
- 来源: daily/2026-06-20.md

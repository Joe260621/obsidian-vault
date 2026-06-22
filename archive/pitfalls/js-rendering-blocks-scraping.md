# JS 渲染页面爬取失败

> 最后更新: 2026-06-21

## 2026-06-20
- 问题: Bitcadet/Darkroom 爬不到文本内容
- 原因: Framer JS 渲染，静态 HTTP 请求拿不到动态内容
- 解决: 改用工作流已提取的声明数据做方向性参考
- 教训: JS 渲染页面需要 headless browser（Playwright/Puppeteer），纯 HTTP 爬虫无法获取动态内容
- 来源: daily/2026-06-20.md

## 2026-06-21
- 问题: deepseek-usage-scraper.js 执行失败，提示"Run login first"
- 原因: DeepSeek Platform 需浏览器登录认证（Playwright storageState），.deepseek-state.json token 过期
- 解决: 暂用手动运行 cost-check.ps1 代替（分析本地转录 JSONL 估算费用）
- 教训: OAuth/Token 认证的 scraper 需要定期重新登录刷新 state，不能做无人值守 cron 任务
- 来源: daily/2026-06-21.md

## 2026-06-21
- 问题: qgsydw-scraper.js 运行成功但输出报错 ENOENT: `g:\Claude\jietu\qgsydw_jobs.json`
- 原因: 脚本内输出路径硬编码为旧电脑的 G 盘路径，笔记本上无此目录
- 解决: 待修改脚本内路径为 `D:\ProjectManagement\Claude\`
- 教训: 跨机器复用的脚本应使用相对路径或环境变量配置，不应硬编码绝对路径
- 来源: daily/2026-06-21.md

// 事招雷达招聘数据抓取 - Playwright版
const { chromium } = require('playwright');
const fs = require('fs');

async function scrapeQGSYDW() {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    await page.setExtraHTTPHeaders({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    });

    try {
        await page.goto('https://www.qgsydw.com/qgsydw/postsearch202603.html?keyword=' + encodeURIComponent('广州') + '&tabType=1', { waitUntil: 'networkidle', timeout: 30000 });
        await page.waitForTimeout(3000);

        // Click "load more" to get additional results
        for (let i = 0; i < 5; i++) {
            const moreBtn = await page.$('.search-box-more');
            if (moreBtn) { await moreBtn.click(); await page.waitForTimeout(1500); }
            else { break; }
        }

        const items = await page.evaluate(() => {
            const results = [];
            document.querySelectorAll('.search-announcement-list-div').forEach(el => {
                const linkEl = el.querySelector('a[href]');
                if (!linkEl) return;
                const link = linkEl.href;
                const title = linkEl.textContent.replace(/\s+/g, ' ').trim();
                if (title.length < 5) return;

                const allLines = el.textContent.split(/[\n\r]+/).map(l => l.trim()).filter(l => l);
                const typeIdx = allLines.findIndex(l => l.match(/招聘|报名|通知|公告|成绩/));
                const type = typeIdx >= 0 ? allLines[typeIdx] : '';
                const dateMatch = el.textContent.match(/(\d{4}\/\d{2}\/\d{2}\s+\d{2}:\d{2}:\d{2})/);
                const date = dateMatch ? dateMatch[1] : '';

                results.push({ title, type, date, link });
            });
            return results;
        });

        // Filter: exclude teacher/doctor/nurse positions
        const excludeWords = [
            '教师', '校医', '护士', '医生', '环卫', '司机', '厨师', '保安', '保洁',
            '副总经理', '总经理', '总监', '副总', '董事长', '校长', '园长',
            '应届', '2026年毕业生', '择业期', '校园', '教育局', '教育系统',
            '体检公告', '成绩查询', '成绩公告', '面试公告',
            '拟聘用', '拟聘', '录用公示', '考察公告', '面试通知',
            '党组织书记', '党员', '党委', '党支部', '支部书记', '党务专干',
            '管理岗', '管培生', '储备干部',
            '投资促进中心', '供销社', '物业管理', '物业',
            'C1', '驾驶证', '驾照',
        ];
        const areaWords = ['天河', '海珠', '荔湾', '番禺', '越秀', '广州'];
        const interestWords = ['管理', '行政', '雇员', '辅助', '社区', '综合', '办公', '文员', '党务', '工会', '后勤', '运营', '社工', '办事员', '科员'];

        const filtered = items.filter(item => {
            const isExcluded = excludeWords.some(w => item.title.includes(w));
            const inArea = areaWords.some(a => item.title.includes(a));
            const isInterest = interestWords.some(w => item.title.includes(w));
            const isRecruit = item.type.includes('招聘公告') || item.type.includes('雇员');
            return !isExcluded && inArea && (isInterest || isRecruit);
        });

        // Output
        console.log('Total: ' + items.length + ' | Filtered: ' + filtered.length + '\n');
        filtered.forEach((item, i) => {
            console.log((i + 1) + '. [' + item.type + '] ' + item.title);
            console.log('   ' + item.date + ' | ' + item.link + '\n');
        });

        // Save
        fs.writeFileSync('D:/ProjectManagement/Claude/jietu/qgsydw_jobs.json', JSON.stringify({
            time: new Date().toISOString(),
            total: items.length,
            filtered: filtered.length,
            jobs: filtered
        }, null, 2), 'utf-8');

        return filtered;

    } catch (err) {
        console.error('Error:', err.message);
        return [];
    } finally {
        await browser.close();
    }
}

scrapeQGSYDW().then(r => console.log('Done. ' + r.length + ' matches'));

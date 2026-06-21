// DeepSeek Usage Scraper — split on "Tokens" label, skip model name digits
const { chromium } = require('playwright');
const fs = require('fs');
const STATE_FILE = 'g:/Claude/scripts/.deepseek-state.json';

async function login() {
    const browser = await chromium.launch({ headless: false });
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.goto('https://platform.deepseek.com/usage');
    console.log('Login then close browser.');
    browser.on('disconnected', async () => {
        try { await context.storageState({ path: STATE_FILE }); console.log('Saved!'); } catch(e) {}
        process.exit(0);
    });
    await new Promise(() => {});
}

async function scrape() {
    if (!fs.existsSync(STATE_FILE)) { console.log('Run login first.'); return; }
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ storageState: STATE_FILE });
    const page = await context.newPage();
    try {
        await page.goto('https://platform.deepseek.com/usage', { waitUntil: 'networkidle', timeout: 30000 });
        await page.waitForTimeout(4000);

        const data = await page.evaluate(() => {
            const result = { balance: '', monthly: '', monthLabel: '', models: [] };
            const bodyText = document.body.innerText;

            // Balance
            let m = bodyText.match(/充值余额[^\d]*¥?\s*([\d,.]+)/);
            if (!m) m = bodyText.match(/余额[^\d]*¥?\s*([\d,.]+)/);
            if (m) result.balance = m[1].replace(/,/g, '');

            // Monthly cost
            m = bodyText.match(/([一二三四五六七八九十]+)月消费[^\d]*¥?\s*([\d,.]+)/);
            if (m) { result.monthLabel = m[1] + '月'; result.monthly = m[2].replace(/,/g, ''); }
            else {
                m = bodyText.match(/月消费[^\d]*¥?\s*([\d,.]+)/);
                if (m) result.monthly = m[1].replace(/,/g, '');
            }

            // Helper: extract numbers from text, removing date-range fragments
            function extractNums(text) {
                const cleaned = text.replace(/\b\d{1,2}-\d{1,2}\b/g, '');
                const nums = [];
                for (const nm of cleaned.matchAll(/([\d,]+)/g)) {
                    const v = parseInt(nm[1].replace(/,/g, ''));
                    if (!isNaN(v)) nums.push(v);
                }
                return nums;
            }

            // Model rows — split on "Tokens" label, skip model-name prefix
            const MODEL_NAMES = ['deepseek-v4-pro', 'deepseek-v4-flash', 'deepseek-chat', 'deepseek-reasoner'];
            const seen = new Set();

            MODEL_NAMES.forEach(name => {
                let pos = 0;
                while ((pos = bodyText.indexOf(name, pos)) >= 0) {
                    const key = `${name}@${pos}`;
                    if (seen.has(key)) { pos += name.length; continue; }
                    seen.add(key);

                    // Grab from model name to next model (or 400 chars max)
                    const endPos = Math.min(
                        ...MODEL_NAMES.map(n => { const p = bodyText.indexOf(n, pos + 1); return p > 0 ? p : Infinity; }),
                        pos + 400
                    );
                    const snippet = bodyText.substring(pos, endPos);

                    // Split on "Tokens" / "Token" label
                    const tokLabel = snippet.search(/Tokens|Token/);

                    // API numbers: start from first "API" or numeric column header after model name
                    const apiStart = snippet.search(/\bAPI\b|\b请求\b/);
                    const apiText = apiStart > 0
                        ? snippet.substring(apiStart, tokLabel > 0 ? tokLabel : snippet.length)
                        : (tokLabel > 0 ? snippet.substring(0, tokLabel) : snippet);

                    const tokenText = tokLabel > 0 ? snippet.substring(tokLabel) : '';

                    const apiNums = extractNums(apiText);
                    // Token section: only first 2-3 numbers belong to this row
                    const tokNums = extractNums(tokenText);

                    // API columns: total, today, yesterday (first 3)
                    // Token columns: total is the first large number; today/yesterday may be separate
                    result.models.push({
                        name,
                        apiCalls: String(apiNums[0] || 0),
                        apiToday: String(apiNums[1] || 0),
                        apiYesterday: String(apiNums[2] || 0),
                        tokens: String(tokNums[0] || 0),
                        tokensToday: String(tokNums[1] || 0),
                        tokensYesterday: String(tokNums[2] || 0),
                        cost: String(tokNums[3] || 0)
                    });

                    pos += name.length;
                }
            });

            return result;
        });

        // --- Output ---
        console.log('=== DeepSeek Usage ===\n');
        console.log(`Balance: ¥${data.balance}`);
        console.log(`Month:  ${data.monthLabel || 'N/A'} | Cost: ¥${data.monthly || '0'}`);
        console.log('');

        if (data.models.length > 0) {
            console.log('--- Per-Model Breakdown ---');
            data.models.forEach(m => {
                const aT = parseInt(m.apiCalls) || 0;
                const aD = parseInt(m.apiToday) || 0;
                const aY = parseInt(m.apiYesterday) || 0;
                const tT = parseInt(m.tokens) || 0;
                const tD = parseInt(m.tokensToday) || 0;
                const tY = parseInt(m.tokensYesterday) || 0;

                console.log(`${m.name}:`);
                console.log(`  API:    ${aT.toLocaleString()} total | ${aD.toLocaleString()} today | ${aY.toLocaleString()} yesterday`);
                console.log(`  Tokens: ${tT.toLocaleString()} total | ${tD.toLocaleString()} today | ${tY.toLocaleString()} yesterday`);
                // Cost column is unreliable in innerText mode — skip
            });

            const todayApi = data.models.reduce((s, m) => s + (parseInt(m.apiToday) || 0), 0);
            const todayTok = data.models.reduce((s, m) => s + (parseInt(m.tokensToday) || 0), 0);
            const yesterdayApi = data.models.reduce((s, m) => s + (parseInt(m.apiYesterday) || 0), 0);
            const yesterdayTok = data.models.reduce((s, m) => s + (parseInt(m.tokensYesterday) || 0), 0);
            const totalTok = data.models.reduce((s, m) => s + (parseInt(m.tokens) || 0), 0);

            console.log('');
            console.log('--- Daily Summary ---');
            console.log(`Today:     ${todayApi.toLocaleString()} calls, ${todayTok.toLocaleString()} tokens`);
            console.log(`Yesterday: ${yesterdayApi.toLocaleString()} calls, ${yesterdayTok.toLocaleString()} tokens`);
            console.log(`Month total tokens: ${totalTok.toLocaleString()}`);
        }

        await context.storageState({ path: STATE_FILE });
    } catch (err) { console.error(err.message); }
    finally { await browser.close(); }
}

(process.argv[2] === 'login' ? login() : scrape()).then(() => console.log('\nDone'));

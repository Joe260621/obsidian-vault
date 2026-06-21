// OCR script using tesseract.js
// Usage: node ocr-images.js
const { createWorker } = require('tesseract.js');
const path = require('path');
const fs = require('fs');

async function ocr() {
    const worker = await createWorker('chi_sim+eng');
    console.log('Worker ready.\n');

    const imgDir = 'G:/Claude/wiki/考编/images';
    const files = fs.readdirSync(imgDir)
        .filter(f => f.endsWith('.png') || f.endsWith('.jpg'))
        .sort();

    for (const file of files) {
        const imgPath = path.join(imgDir, file);
        const sizeKb = (fs.statSync(imgPath).size / 1024).toFixed(0);
        console.log(`[${file}] (${sizeKb}KB)`);
        const start = Date.now();

        const { data: { text } } = await worker.recognize(imgPath);

        const elapsed = ((Date.now() - start) / 1000).toFixed(1);
        const preview = text.replace(/\s+/g, ' ').trim().substring(0, 600);
        console.log(`  ${elapsed}s → ${preview}`);
        console.log();
    }

    await worker.terminate();
    console.log('Done!');
}

ocr().catch(e => { console.error(e); process.exit(1); });

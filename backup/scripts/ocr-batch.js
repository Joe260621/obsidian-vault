// Batch OCR all images in a directory and save results
// Usage: node ocr-batch.js <image_dir> <output_file>
const { createWorker } = require('tesseract.js');
const path = require('path');
const fs = require('fs');

const imgDir = process.argv[2] || 'G:/Claude/wiki/考编/images/科推';
const outFile = process.argv[3] || 'G:/Claude/wiki/考编/images/科推/ocr-results.txt';

async function ocr() {
    const worker = await createWorker('chi_sim+eng');
    console.log('Worker ready.');

    const files = fs.readdirSync(imgDir)
        .filter(f => /\.(png|jpg|jpeg)$/i.test(f))
        .sort((a, b) => {
            const na = parseInt(a.match(/\d+/)?.[0] || '0');
            const nb = parseInt(b.match(/\d+/)?.[0] || '0');
            return na - nb;
        });

    console.log(`Processing ${files.length} images...\n`);
    const results = [];
    const startAll = Date.now();

    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const imgPath = path.join(imgDir, file);
        const t0 = Date.now();

        try {
            const { data: { text } } = await worker.recognize(imgPath);
            const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
            const clean = text.replace(/\s+/g, ' ').trim();

            results.push({ file, text: clean });

            const progress = `${i + 1}/${files.length}`;
            const totalElapsed = ((Date.now() - startAll) / 1000).toFixed(0);
            console.log(`[${progress}] ${file} (${elapsed}s) → ${clean.substring(0, 80)}`);
        } catch (e) {
            results.push({ file, text: `OCR_ERROR: ${e.message}` });
            console.log(`[${i + 1}/${files.length}] ${file} ERROR: ${e.message}`);
        }
    }

    await worker.terminate();

    // Save results
    const output = results.map(r => `--- ${r.file} ---\n${r.text}\n`).join('\n');
    fs.writeFileSync(outFile, output, 'utf-8');

    const totalTime = ((Date.now() - startAll) / 1000).toFixed(0);
    const nonEmpty = results.filter(r => r.text && r.text.length > 5).length;
    console.log(`\nDone! ${files.length} images in ${totalTime}s. Non-empty: ${nonEmpty}/${files.length}`);
    console.log(`Results saved to: ${outFile}`);
}

ocr().catch(e => { console.error(e); process.exit(1); });

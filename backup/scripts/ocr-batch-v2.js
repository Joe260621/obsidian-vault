/**
 * Phase 2b OCR: Process rendered PNG pages with tesseract.js.
 * Walks _ocr_pages/ directory, OCRs each PDF's pages, saves combined .txt.
 */
const { createWorker } = require('tesseract.js');
const fs = require('fs');
const path = require('path');

const OCR_PAGES_DIR = process.argv[2] || 'G:/Claude/wiki/考编/_extracted/_ocr_pages';
const OUT_DIR = process.argv[3] || 'G:/Claude/wiki/考编/_extracted/_ocr_results';

if (!fs.existsSync(OCR_PAGES_DIR)) {
    console.error('OCR pages directory not found:', OCR_PAGES_DIR);
    process.exit(1);
}
fs.mkdirSync(OUT_DIR, { recursive: true });

async function ocrDirectory(pdfDir) {
    const pdfName = path.basename(pdfDir);
    const outFile = path.join(OUT_DIR, pdfName + '.txt');

    // Check if already done
    if (fs.existsSync(outFile)) {
        const existing = fs.readFileSync(outFile, 'utf-8');
        // Count non-empty OCR results
        const pages = existing.split('--- Page ').filter(s => s.includes('OCR_TEXT:')).length;
        const totalFiles = fs.readdirSync(pdfDir).filter(f => f.endsWith('.png')).length;
        if (pages >= totalFiles * 0.9) {
            console.log(`  SKIP ${pdfName} (already OCR'd: ${pages}/${totalFiles} pages)`);
            return { name: pdfName, pages, totalFiles, skipped: true };
        }
    }

    const files = fs.readdirSync(pdfDir)
        .filter(f => /\.png$/i.test(f))
        .sort((a, b) => {
            const na = parseInt(a.match(/\d+/)?.[0] || '0');
            const nb = parseInt(b.match(/\d+/)?.[0] || '0');
            return na - nb;
        });

    if (files.length === 0) {
        console.log(`  EMPTY ${pdfName}`);
        return { name: pdfName, pages: 0, totalFiles: 0, empty: true };
    }

    console.log(`  OCR: ${pdfName} (${files.length} pages)`);
    const worker = await createWorker('chi_sim+eng');
    const results = [];
    const t0 = Date.now();

    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const imgPath = path.join(pdfDir, file);
        const pageNum = file.match(/page_(\d+)/)?.[1] || String(i+1);
        const pt0 = Date.now();

        try {
            const { data: { text } } = await worker.recognize(imgPath);
            const elapsed = ((Date.now() - pt0) / 1000).toFixed(1);
            const clean = text.replace(/\s+/g, ' ').trim();
            results.push(`--- Page ${pageNum} ---\nOCR_TEXT: ${clean}\n`);

            const totalElapsed = ((Date.now() - t0) / 1000).toFixed(0);
            const eta = files.length - i - 1 > 0
                ? ((Date.now() - t0) / (i + 1) * (files.length - i - 1) / 1000).toFixed(0)
                : '0';
            const preview = clean.substring(0, 60);
            console.log(`    [${i+1}/${files.length}] p${pageNum} ${elapsed}s ETA:${eta}s | ${preview}...`);
        } catch (e) {
            results.push(`--- Page ${pageNum} ---\nOCR_ERROR: ${e.message}\n`);
            console.log(`    [${i+1}/${files.length}] p${pageNum} ERROR: ${e.message}`);
        }
    }

    await worker.terminate();

    // Save
    const header = `# OCR: ${pdfName}\n# Pages: ${files.length}\n# Date: ${new Date().toISOString()}\n\n`;
    fs.writeFileSync(outFile, header + results.join('\n'), 'utf-8');

    const totalTime = ((Date.now() - t0) / 1000).toFixed(0);
    const nonEmpty = results.filter(r => !r.includes('OCR_ERROR') && r.includes('OCR_TEXT:') && r.split('OCR_TEXT:')[1]?.trim().length > 5).length;
    console.log(`    DONE ${pdfName}: ${nonEmpty}/${files.length} non-empty, ${totalTime}s`);
    return { name: pdfName, pages: files.length, nonEmpty, totalTime };
}

async function main() {
    // Get all PDF directories
    const dirs = fs.readdirSync(OCR_PAGES_DIR, { withFileTypes: true })
        .filter(d => d.isDirectory())
        .map(d => path.join(OCR_PAGES_DIR, d.name))
        .sort();

    console.log(`Found ${dirs.length} PDF directories to OCR\n`);

    const allStart = Date.now();
    const results = [];

    for (let i = 0; i < dirs.length; i++) {
        console.log(`[${i+1}/${dirs.length}]`);
        const result = await ocrDirectory(dirs[i]);
        results.push(result);
    }

    // Summary
    const totalPages = results.reduce((s, r) => s + (r.pages || 0), 0);
    const skipped = results.filter(r => r.skipped).length;
    const processed = results.filter(r => !r.skipped && !r.empty).length;
    const totalTime = ((Date.now() - allStart) / 1000).toFixed(0);

    console.log(`\n${'='.repeat(50)}`);
    console.log(`OCR Complete!`);
    console.log(`PDFs: ${results.length} | Processed: ${processed} | Skipped: ${skipped}`);
    console.log(`Total pages: ${totalPages} | Total time: ${totalTime}s`);
    console.log(`Output: ${OUT_DIR}`);
}

main().catch(e => { console.error(e); process.exit(1); });

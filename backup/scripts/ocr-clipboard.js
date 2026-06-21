// OCR Clipboard — Extract text from clipboard image
// Uses tesseract.js (pure JS, offline) or Qwen-VL API
process.chdir(__dirname);
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Load API keys from env or Windows registry
function loadEnv(key) {
  if (process.env[key]) return process.env[key];
  try {
    const result = execSync(
      `powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable('${key}','User')"`,
      { encoding: 'utf8', timeout: 3000 }
    ).trim();
    if (result) process.env[key] = result;
    return result || null;
  } catch (e) {
    return null;
  }
}

const QWEN_API_KEY = loadEnv('QWEN_API_KEY');
const KIMI_API_KEY = loadEnv('KIMI_API_KEY');

const tmpDir = os.tmpdir();
const imgFile = path.join(tmpDir, `clipboard_ocr_${Date.now()}.png`);

// 1. Read clipboard image via PowerShell
try {
  execSync(
    `powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $img = [System.Windows.Forms.Clipboard]::GetImage(); if (-not $img) { exit 1 }; $img.Save('${imgFile.replace(/\\/g, '\\\\')}', [System.Drawing.Imaging.ImageFormat]::Png)"`,
    { encoding: 'utf8', timeout: 5000 }
  );
} catch (e) {
  console.log('ERROR: 剪切板中没有图片');
  process.exit(1);
}

// OCR engine selection
// --tesseract: force tesseract.js even if API keys are available
// --qwen: force Qwen VL (requires QWEN_API_KEY)
// --kimi: force Kimi (requires KIMI_API_KEY)
// Default: Qwen VL > Kimi > tesseract.js (based on available keys)
const useQwen = process.argv.includes('--qwen') && QWEN_API_KEY;
const useKimi = process.argv.includes('--kimi') && KIMI_API_KEY;
const forceTesseract = process.argv.includes('--tesseract');
const preferQwen = QWEN_API_KEY && !forceTesseract;
const preferKimi = KIMI_API_KEY && !forceTesseract && !preferQwen;

if (useQwen || preferQwen) {
  ocrViaQwen(imgFile);
} else if (useKimi || preferKimi) {
  ocrViaKimi(imgFile);
} else {
  ocrViaTesseract(imgFile);
}

// --- OCR backends ---

function ocrViaQwen(imgFile) {
  const base64 = fs.readFileSync(imgFile).toString('base64');
  const body = JSON.stringify({
    model: 'qwen-vl-plus',
    messages: [{
      role: 'user',
      content: [
        { type: 'image_url', image_url: { url: `data:image/png;base64,${base64}` } },
        { type: 'text', text: '请提取图片中所有文字，按原格式输出，不要加解释。' }
      ]
    }]
  });

  // Write body to temp file to avoid shell escaping issues
  const bodyFile = path.join(os.tmpdir(), `qwen_req_${Date.now()}.json`);
  fs.writeFileSync(bodyFile, body, 'utf8');

  try {
    const result = execSync(
      `curl.exe -s -X POST "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" -H "Authorization: Bearer ${QWEN_API_KEY}" -H "Content-Type: application/json" -d @"${bodyFile}"`,
      { encoding: 'utf8', timeout: 30000 }
    );
    const json = JSON.parse(result);
    const text = json.choices[0].message.content;
    console.log('=== OCR (Qwen VL) ===');
    console.log(text);
  } catch (e) {
    console.log('Qwen API failed:', e.message);
    // Fallback to tesseract
    ocrViaTesseract(imgFile);
    return;
  } finally {
    try { fs.unlinkSync(bodyFile); } catch (e) {}
    try { fs.unlinkSync(imgFile); } catch (e) {}
  }
}

function ocrViaKimi(imgFile) {
  const base64 = fs.readFileSync(imgFile).toString('base64');
  const body = JSON.stringify({
    model: 'moonshot-v1-8k-vision-preview',
    messages: [{
      role: 'user',
      content: [
        { type: 'image_url', image_url: { url: `data:image/png;base64,${base64}` } },
        { type: 'text', text: 'Extract all text from this image. Output the text only, no explanations.' }
      ]
    }]
  });

  try {
    const result = execSync(
      `curl.exe -s -X POST "https://api.moonshot.cn/v1/chat/completions" -H "Authorization: Bearer ${process.env.KIMI_API_KEY}" -H "Content-Type: application/json" -d "${body.replace(/"/g, '\\"')}"`,
      { encoding: 'utf8', timeout: 30000 }
    );
    const json = JSON.parse(result);
    const text = json.choices[0].message.content;
    console.log('=== OCR (Kimi) ===');
    console.log(text);
  } catch (e) {
    console.log('Kimi API failed:', e.message);
    process.exit(2);
  } finally {
    fs.unlinkSync(imgFile);
  }
}

async function ocrViaTesseract(imgFile) {
  const Tesseract = require('tesseract.js');

  console.log('OCR: tesseract.js (chi_sim+eng)...');

  try {
    const worker = await Tesseract.createWorker('chi_sim+eng', 1, {
      logger: m => {
        if (m.status === 'downloading traineddata') {
          process.stderr.write('.');
        } else if (m.status === 'recognizing text') {
          process.stderr.write('#');
        }
      }
    });

    const { data: { text } } = await worker.recognize(imgFile);
    await worker.terminate();

    console.log('\n=== OCR ===');
    console.log(text.trim() || '(No text found)');
    try { fs.unlinkSync(imgFile); } catch (e) {}
  } catch (err) {
    // Fallback: try English only
    console.log('\nChinese failed, trying English only...');
    try {
      const worker = await Tesseract.createWorker('eng', 1, {
        logger: m => {}
      });
      const { data: { text } } = await worker.recognize(imgFile);
      await worker.terminate();

      console.log('=== OCR (English) ===');
      console.log(text.trim() || '(No text found)');
      try { fs.unlinkSync(imgFile); } catch (e) {}
    } catch (e) {
      console.log('ERROR: OCR failed -', e.message);
      try { fs.unlinkSync(imgFile); } catch (e) {}
      process.exit(2);
    }
  }
}

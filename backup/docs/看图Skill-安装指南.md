# 看图 Skill — 安装与使用指南

> 截图 → OCR 提取文字 → AI 分析回答。让不会看图的 AI（如 DeepSeek）也能"看懂图片"。

## 核心原理

```
截图 (Win+Shift+S) → 图片入剪切板
                  → 触发"看图"命令
                  → OCR 引擎提取文字（tesseract.js / Qwen VL / Kimi）
                  → 文字传给 AI 分析
                  → AI 用文字内容回答你的问题
```

**成本极低**：OCR 只提取文字（几十 token），不是把整张图发给大模型（几千 token）。

## 第一步：安装 OCR 引擎

### 方案 A：tesseract.js（免费、离线、无需 API Key）

```bash
# 在 Claude Code 工作目录下创建 scripts 文件夹并安装
mkdir scripts
cd scripts
npm init -y
npm install tesseract.js
```

首次使用时会下载语言包（~30MB），后续离线可用。

- 优点：完全免费，无需联网
- 缺点：中英文混排识别率一般，排版复杂时容易乱

### 方案 B：千问 VL API（推荐，识别更准）

注册 [DashScope](https://dashscope.aliyun.com/) 获取 API Key，然后：

**Windows PowerShell：**
```powershell
$env:QWEN_API_KEY = "sk-你的key"
```

**macOS / Linux：**
```bash
export QWEN_API_KEY="sk-你的key"
```

也可写入 `~/.claude/settings.json` 的 `env` 字段永久生效。

- 优点：识别准确，中英文混排效果好
- 缺点：需要 API Key，有少量费用（每张图约 0.001 元）

### 方案 C：Kimi API

```bash
export KIMI_API_KEY="sk-你的key"
```

## 第二步：创建 OCR 脚本

在 Claude Code 工作目录下创建 `scripts/ocr-clipboard.js`：

```javascript
// OCR Clipboard — Extract text from clipboard image
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const tmpDir = os.tmpdir();
const imgFile = path.join(tmpDir, `clipboard_ocr_${Date.now()}.png`);

// --- Platform: Save clipboard image ---
const isWin = process.platform === 'win32';
const isMac = process.platform === 'darwin';

if (isWin) {
  try {
    execSync(
      `powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $img = [System.Windows.Forms.Clipboard]::GetImage(); if (-not $img) { exit 1 }; $img.Save('${imgFile.replace(/\\/g, '\\\\')}', [System.Drawing.Imaging.ImageFormat]::Png)"`,
      { encoding: 'utf8', timeout: 5000 }
    );
  } catch (e) {
    console.log('ERROR: No image in clipboard');
    process.exit(1);
  }
} else if (isMac) {
  try {
    execSync(`osascript -e 'tell application "Finder" to set thePicture to (the clipboard as «class PNGf»)' -e 'if thePicture is not {} then set imgFile to "${imgFile}"'`, { encoding: 'utf8' });
    // Alternative: use pngpaste
    execSync(`pngpaste "${imgFile}"`, { encoding: 'utf8', timeout: 5000 });
  } catch (e) {
    // Fallback: try reading from clipboard via osascript
    try {
      execSync(`osascript -e 'set img to (the clipboard as «class PNGf»)' -e 'set f to open for access "${imgFile}" with write permission' -e 'write img to f' -e 'close access f'`, { encoding: 'utf8' });
    } catch(e2) {
      console.log('ERROR: No image in clipboard (macOS needs pngpaste: brew install pngpaste)');
      process.exit(1);
    }
  }
} else {
  console.log('ERROR: Unsupported platform. Linux needs xclip: xclip -selection clipboard -t image/png -o > ' + imgFile);
  process.exit(1);
}

// --- OCR engine selection ---
const useQwen = process.argv.includes('--qwen') && process.env.QWEN_API_KEY;
const useKimi = process.argv.includes('--kimi') && process.env.KIMI_API_KEY;

if (useQwen) ocrViaQwen();
else if (useKimi) ocrViaKimi();
else ocrViaTesseract();

// --- Tesseract.js (free, offline) ---
function ocrViaTesseract() {
  const Tesseract = require('tesseract.js');
  console.log('OCR: tesseract.js (chi_sim+eng)...');
  Tesseract.recognize(imgFile, 'chi_sim+eng', {
    logger: m => { if (m.status === 'recognizing text') process.stderr.write('.'); }
  }).then(({ data: { text } }) => {
    console.log('\n=== OCR Result ===');
    console.log(text.trim() || '(No text found)');
    cleanup();
  }).catch(err => {
    // Fallback: English only
    Tesseract.recognize(imgFile, 'eng')
      .then(({ data: { text } }) => {
        console.log('\n=== OCR Result (English) ===');
        console.log(text.trim() || '(No text found)');
        cleanup();
      }).catch(e => { console.log('OCR failed:', e.message); cleanup(); process.exit(2); });
  });
}

// --- Qwen VL API (high accuracy) ---
function ocrViaQwen() {
  const base64 = fs.readFileSync(imgFile).toString('base64');
  const body = JSON.stringify({
    model: 'qwen-vl-plus',
    messages: [{ role: 'user', content: [
      { type: 'image_url', image_url: { url: `data:image/png;base64,${base64}` } },
      { type: 'text', text: '请提取图片中所有文字，按原格式输出，不要加解释。' }
    ]}]
  });
  const cmd = `curl -s -X POST "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" -H "Authorization: Bearer ${process.env.QWEN_API_KEY}" -H "Content-Type: application/json" -d '${body.replace(/'/g, "'\\''")}'`;
  const result = execSync(cmd, { encoding: 'utf8', timeout: 30000 });
  const text = JSON.parse(result).choices[0].message.content;
  console.log('=== OCR (Qwen VL) ===');
  console.log(text);
  cleanup();
}

// --- Kimi API ---
function ocrViaKimi() {
  const base64 = fs.readFileSync(imgFile).toString('base64');
  const body = JSON.stringify({
    model: 'moonshot-v1-8k-vision-preview',
    messages: [{ role: 'user', content: [
      { type: 'image_url', image_url: { url: `data:image/png;base64,${base64}` } },
      { type: 'text', text: '请提取图片中所有文字，按原格式输出，不要加解释。' }
    ]}]
  });
  const cmd = `curl -s -X POST "https://api.moonshot.cn/v1/chat/completions" -H "Authorization: Bearer ${process.env.KIMI_API_KEY}" -H "Content-Type: application/json" -d '${body.replace(/'/g, "'\\''")}'`;
  const result = execSync(cmd, { encoding: 'utf8', timeout: 30000 });
  const text = JSON.parse(result).choices[0].message.content;
  console.log('=== OCR (Kimi) ===');
  console.log(text);
  cleanup();
}

function cleanup() {
  try { fs.unlinkSync(imgFile); } catch(e) {}
}
```

## 第三步：注册 Skill

创建 `.claude/skills/看图.md`：

```markdown
# 看图 Skill — 识别图片文字 + 智能分析

## 触发词
- "看图"
- "识别图片" / "OCR"
- "图片里写了什么" / "帮我看看这张图"
- "/看图"

## 执行方式
node scripts/ocr-clipboard.js

如果用户说"用千问看图"：
node scripts/ocr-clipboard.js --qwen

如果用户说"用kimi看图"：
node scripts/ocr-clipboard.js --kimi

## 提示词模板
OCR 返回文字后，根据用户问题分析：
- 没具体问题 → 用一句话总结图片内容
- 有具体问题 → 基于 OCR 文字回答问题
```

## 第四步：配置权限（可选）

如果 Claude Code 弹出权限确认，在 `.claude/settings.json` 添加：

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "PowerShell(*)"
    ]
  }
}
```

## 使用方式

1. **截图**：`Win+Shift+S`（Windows）/ `Cmd+Shift+4`（Mac）
2. **在 Claude Code 中**：说"看图"或"识别图片，帮我总结内容"
3. **在飞书中（需 cc-connect）**：发 `/看图`

## 文件清单

```
<工作目录>/
├── scripts/
│   ├── ocr-clipboard.js   ← OCR 核心脚本
│   ├── package.json
│   └── node_modules/
│       └── tesseract.js/  ← 免费 OCR 引擎
└── .claude/
    └── skills/
        └── 看图.md        ← Skill 触发定义
```

## 常见问题

| 问题 | 解决 |
|------|------|
| "剪切板中没有图片" | 先截图（Win+Shift+S），确保图片在剪切板 |
| tesseract.js 中文乱码 | 首次运行会下载中文语言包，需联网；或改用千问 VL |
| macOS 剪切板读不到 | 安装 pngpaste: `brew install pngpaste` |
| 图片太大识别慢 | tesseract.js 处理 4K 截图约 5-10 秒，正常 |

## cc-connect 集成（可选）

在 `config.toml` 添加飞书斜杠命令：

```toml
[[commands]]
name = "看图"
description = "识别剪切板图片文字并分析"
prompt = "请执行: node scripts/ocr-clipboard.js。拿到 OCR 文字后，{{args:帮我一句话总结图片内容}}"

[[commands]]
name = "ocr"
description = "只提取图片文字，不做分析"
prompt = "请执行: node scripts/ocr-clipboard.js。把 OCR 结果直接输出，不用分析。"
```

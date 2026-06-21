// OCR script - extract text from clipboard image
// Uses Windows built-in OCR via PowerShell (stable path)
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const tmpFile = path.join(process.env.TEMP || '/tmp', `clipboard_ocr_${Date.now()}.png`);

// Step 1: Save clipboard image via PowerShell
try {
  execSync(`powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $img = [System.Windows.Forms.Clipboard]::GetImage(); if (-not $img) { exit 1 }; $img.Save('${tmpFile}', [System.Drawing.Imaging.ImageFormat]::Png); Write-Output 'OK'"`, { encoding: 'utf8' });
} catch (e) {
  console.log('ERROR: 剪切板中没有图片');
  process.exit(1);
}

// Step 2: OCR via Windows Runtime (separate ps1 for WinRT stability)
const ocrPs1 = `
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 })[0]

# Load image file
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
$getFile = [Windows.Storage.StorageFile].GetMethod('GetFileFromPathAsync')
$task = $getFile.Invoke($null, @('${tmpFile}'))
$asTask = $asTaskGeneric.MakeGenericMethod([Windows.Storage.StorageFile])
$file = $asTask.Invoke($null, @($task)).GetAwaiter().GetResult()
$stream = $file.OpenReadAsync().GetAwaiter().GetResult()

# Decode bitmap
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null
$decoder = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream).GetAwaiter().GetResult()
$bitmap = $decoder.GetSoftwareBitmapAsync().GetAwaiter().GetResult()

# OCR
[Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
if (-not $engine) {
  $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage('en')
}
$result = $engine.RecognizeAsync($bitmap).GetAwaiter().GetResult()
$result.Lines | ForEach-Object { $_.Text }
`;

const ocrFile = path.join(process.env.TEMP || '/tmp', `ocr_${Date.now()}.ps1`);
fs.writeFileSync(ocrFile, ocrPs1, 'utf8');

try {
  const result = execSync(`powershell -NoProfile -ExecutionPolicy Bypass -File "${ocrFile}"`, { encoding: 'utf8', timeout: 30000 });

  // Cleanup
  try { fs.unlinkSync(tmpFile); } catch(e) {}
  try { fs.unlinkSync(ocrFile); } catch(e) {}

  const text = result.trim();
  if (text) {
    console.log('=== OCR 结果 ===');
    console.log(text);
  } else {
    console.log('(图片中未识别到文字)');
  }
} catch (e) {
  console.log('OCR 失败:', e.stderr || e.message);
  process.exit(2);
}

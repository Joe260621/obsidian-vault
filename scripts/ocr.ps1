# OCR Script - Extract text from clipboard image
# Windows OCR (free) or Qwen-VL/Kimi API (if keys configured)
param([switch]$UseQwen)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Read clipboard
$img = [System.Windows.Forms.Clipboard]::GetImage()
if (-not $img) {
    Write-Output "ERROR: No image in clipboard"
    exit 1
}

$tempFile = [System.IO.Path]::GetTempPath() + "clipboard_ocr_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
$img.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "Image: $($img.Width)x$($img.Height) ($([math]::Round((Get-Item $tempFile).Length/1KB,1)) KB)"

# 2. OCR
if ($UseQwen -and $env:QWEN_API_KEY) {
    # Qwen-VL
    $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($tempFile))
    $body = @{
        model = "qwen-vl-plus"
        messages = @(
            @{
                role = "user"
                content = @(
                    @{ type = "image_url"; image_url = @{ url = "data:image/png;base64,$base64" } }
                    @{ type = "text"; text = "Extract all text from this image. Output the text only, no explanations." }
                )
            }
        )
    } | ConvertTo-Json -Depth 5 -Compress

    $headers = @{ Authorization = "Bearer $env:QWEN_API_KEY"; "Content-Type" = "application/json" }
    $resp = Invoke-RestMethod -Uri "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" -Method Post -Body $body -Headers $headers -TimeoutSec 30
    $text = $resp.choices[0].message.content
    Write-Output "=== OCR (Qwen VL) ==="
    Write-Output $text
} elseif ($env:KIMI_API_KEY) {
    # Kimi
    $base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($tempFile))
    $content = @(
        @{ type = "image_url"; image_url = @{ url = "data:image/png;base64,$base64" } }
        @{ type = "text"; text = "Extract all text from this image. Output the text only, no explanations." }
    )
    $body = @{
        model = "moonshot-v1-8k-vision-preview"
        messages = @(@{ role = "user"; content = $content })
    } | ConvertTo-Json -Depth 6 -Compress

    $headers = @{ Authorization = "Bearer $($env:KIMI_API_KEY)"; "Content-Type" = "application/json" }
    $resp = Invoke-RestMethod -Uri "https://api.moonshot.cn/v1/chat/completions" -Method Post -Body $body -Headers $headers -TimeoutSec 30
    $text = $resp.choices[0].message.content
    Write-Output "=== OCR (Kimi) ==="
    Write-Output $text
} else {
    # Windows built-in OCR (free, offline)
    Write-Output "OCR: Windows built-in"
    $psScript = @"
Add-Type -AssemblyName System.Runtime.WindowsRuntime

`$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { `$_.Name -eq 'AsTask' -and `$_.GetParameters().Count -eq 1 })[0]

[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
`$getFile = [Windows.Storage.StorageFile].GetMethod('GetFileFromPathAsync')
`$task = `$getFile.Invoke(`$null, @('$tempFile'))
`$asTask = `$asTaskGeneric.MakeGenericMethod([Windows.Storage.StorageFile])
`$file = `$asTask.Invoke(`$null, @(`$task)).GetAwaiter().GetResult()
`$stream = `$file.OpenReadAsync().GetAwaiter().GetResult()

[Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime] | Out-Null
`$decoder = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync(`$stream).GetAwaiter().GetResult()
`$bitmap = `$decoder.GetSoftwareBitmapAsync().GetAwaiter().GetResult()

[Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
`$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
if (-not `$engine) { `$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage('en') }
if (-not `$engine) { Write-Output 'ERROR: OCR engine unavailable'; exit 3 }
`$result = `$engine.RecognizeAsync(`$bitmap).GetAwaiter().GetResult()
`$text = (`$result.Lines | ForEach-Object { `$_.Text }) -join [System.Environment]::NewLine
Write-Output `$text
"@
    $psFile = [System.IO.Path]::GetTempPath() + "ocr_winrt.ps1"
    [System.IO.File]::WriteAllText($psFile, $psScript, [System.Text.UTF8Encoding]::new($false))
    $text = & powershell -NoProfile -ExecutionPolicy Bypass -File $psFile 2>&1
    Remove-Item $psFile -Force -ErrorAction SilentlyContinue
    Write-Output "=== OCR Result ==="
    Write-Output $text
}

# Cleanup temp image
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

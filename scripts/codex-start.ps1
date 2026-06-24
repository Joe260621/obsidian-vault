# Codex CLI + DeepSeek Launcher
$env:Path = "G:\nodejs;C:\Users\YU\AppData\Roaming\npm;" + $env:Path

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  Codex CLI + DeepSeek Launcher" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if proxy already running
Write-Host "[1/3] Checking proxy..." -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:4000/v1/models" -UseBasicParsing -TimeoutSec 2
    Write-Host "      Proxy already running." -ForegroundColor Green
} catch {
    Write-Host "      Proxy not running, starting..." -ForegroundColor Yellow
    Write-Host "[2/3] Starting mimo2codex proxy..." -ForegroundColor Yellow

    # Load API key from user environment variable
    $dsKey = [Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY", "User")
    $env:DS_API_KEY = $dsKey

    $mimo2codexJs = "C:\Users\YU\AppData\Roaming\npm\node_modules\mimo2codex\dist\cli.js"
    Start-Process -FilePath "G:\nodejs\node.exe" -ArgumentList "`"$mimo2codexJs`"", "--model", "ds", "--port", "4000" -WindowStyle Minimized

    # Wait until proxy responds
    $retries = 0
    while ($retries -lt 15) {
        Start-Sleep -Seconds 2
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:4000/v1/models" -UseBasicParsing -TimeoutSec 2
            Write-Host "      Proxy ready!" -ForegroundColor Green
            break
        } catch {
            $retries++
        }
    }
    if ($retries -ge 15) {
        Write-Host "      WARNING: Proxy may not have started. Codex will try anyway." -ForegroundColor Red
    }
}

# 3. Launch Codex
Write-Host "[3/3] Launching Codex CLI..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Type /help for commands, Ctrl+C to exit." -ForegroundColor Gray
Write-Host ""
& codex

# When Codex exits
Write-Host ""
Write-Host "Codex exited. Proxy is still running in background." -ForegroundColor Gray
Write-Host "To stop proxy: open Task Manager and kill node.exe processes." -ForegroundColor Gray

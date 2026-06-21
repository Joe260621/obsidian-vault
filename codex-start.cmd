@echo off
chcp 65001 >nul
title Codex + DeepSeek

echo ==============================
echo   Codex CLI — DeepSeek 启动器
echo ==============================
echo.

REM 1. 检查代理是否已经在跑
echo [1/3] 检查翻译代理...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:4000/health' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo       代理已在运行，跳过启动
    goto :codex
)

REM 2. 启动代理（后台窗口）
echo [2/3] 启动翻译代理...
set "PATH=G:\nodejs;C:\Users\YU\AppData\Roaming\npm;%PATH%"
start "mimo2codex" /min cmd /c "mimo2codex --model ds --port 4000"
echo       等待代理就绪...
:wait
timeout /t 2 /nobreak >nul
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:4000/health' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo       等待中...
    goto :wait
)
echo       代理启动成功！

REM 3. 启动 Codex
:codex
echo [3/3] 启动 Codex CLI...
echo.
set "PATH=G:\nodejs;C:\Users\YU\AppData\Roaming\npm;%PATH%"
codex
exit /b %errorlevel%

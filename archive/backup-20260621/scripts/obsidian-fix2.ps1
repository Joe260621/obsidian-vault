# Kill all Obsidian, then restart with GPU disabled
Get-Process -Name Obsidian -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2

# Try opening the Claude vault directly with GPU disabled
Write-Host "Launching Obsidian with --disable-gpu, opening G:\Claude vault..."
$proc = Start-Process -FilePath "G:\Obsidian\Obsidian.exe" -ArgumentList "--disable-gpu", "G:\Claude" -PassThru
Write-Host "PID: $($proc.Id)"
Start-Sleep 5

# Check
$procs = Get-Process -Name Obsidian -ErrorAction SilentlyContinue
Write-Host "Obsidian processes: $($procs.Count)"
foreach ($p in $procs) {
    if ($p.MainWindowHandle -ne 0) {
        Write-Host "SUCCESS: Window found PID=$($p.Id) Title='$($p.MainWindowTitle)'"
    }
}
if (($procs | Where-Object { $_.MainWindowHandle -ne 0 }).Count -eq 0) {
    Write-Host "Still no window. Will try without GPU flag..."
    Get-Process -Name Obsidian -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 2

    # Try safemode
    Write-Host "Launching Obsidian in restricted mode (safe vault)..."
    $proc = Start-Process -FilePath "G:\Obsidian\Obsidian.exe" -ArgumentList "--disable-gpu", "--sandbox", "G:\Claude" -PassThru
    Start-Sleep 6

    $procs = Get-Process -Name Obsidian -ErrorAction SilentlyContinue
    Write-Host "Obsidian processes: $($procs.Count)"
    foreach ($p in $procs) {
        Write-Host "PID=$($p.Id) HWND=$($p.MainWindowHandle) Title='$($p.MainWindowTitle)'"
    }
}

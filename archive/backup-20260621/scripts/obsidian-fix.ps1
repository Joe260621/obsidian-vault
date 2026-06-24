# Bring Obsidian window to front
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out int pid);
}
"@

$procs = Get-Process -Name Obsidian -ErrorAction SilentlyContinue
Write-Host "Obsidian processes: $($procs.Count)"

$found = $false
foreach ($p in $procs) {
    if ($p.MainWindowHandle -ne 0) {
        $found = $true
        Write-Host "Window found: PID=$($p.Id) HWND=$($p.MainWindowHandle) Title='$($p.MainWindowTitle)'"
        # SW_RESTORE=9, bring to front
        [Win32]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
        [Win32]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
        Write-Host "  → Brought to foreground"
    } else {
        Write-Host "No window: PID=$($p.Id)"
    }
}

if (-not $found) {
    Write-Host "No visible window found — Obsidian may be a background/tray-only process"
    Write-Host "Killing all Obsidian processes and restarting..."
    Get-Process -Name Obsidian -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 2
    Start-Process -FilePath "G:\Obsidian\Obsidian.exe"
    Write-Host "Restarted Obsidian"
}

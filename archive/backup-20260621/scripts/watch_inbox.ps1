# 后台监控 Downloads → 只搬运幕布导出的 HTML → Inbox
# 运行一次常驻，Ctrl+C 或关窗停止

$Downloads = "G:\Download"
$Inbox = "G:\quark\Obsidian笔记\Inbox"

Write-Output "=== Inbox Watcher (幕布专用) ==="
Write-Output "Watching: $Downloads"
Write-Output "Target: $Inbox"
Write-Output "Close window to stop."
Write-Output ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $Downloads
$watcher.Filter = "*.html"
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName
$watcher.EnableRaisingEvents = $true

$action = {
    $file = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    Start-Sleep -Milliseconds 1500
    if (-not (Test-Path $file)) { return }

    # 检查是否是幕布导出的文件
    $isMubu = $false
    try {
        $text = Get-Content $file -Raw -Encoding UTF8 -TotalCount 50 -ErrorAction Stop
        if ($text -match 'mm-editor|node-list|mubu\.com') {
            $isMubu = $true
        }
    } catch {}

    if ($isMubu) {
        $dest = Join-Path $Inbox $name
        if (Test-Path $dest) {
            $dest = Join-Path $Inbox "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$name"
        }
        Move-Item $file -Destination $dest -Force -ErrorAction SilentlyContinue
        if ($?) { Write-Output "[$(Get-Date -Format 'HH:mm:ss')] 幕布 → $name" }
    } else {
        Write-Output "[$(Get-Date -Format 'HH:mm:ss')] 跳过 (非幕布): $name"
    }
}

Register-ObjectEvent $watcher "Created" -Action $action | Out-Null

try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    $watcher.Dispose()
}

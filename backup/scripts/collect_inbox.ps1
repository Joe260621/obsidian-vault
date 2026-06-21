# 一键归位：把 Downloads 里的幕布/HTML 文件自动移入 Inbox
# 用法：幕布导出后，双击运行这个 bat 文件，或在 PowerShell 里跑 .\collect_inbox.ps1

$Downloads = "$env:USERPROFILE\Downloads"
$Inbox = "G:\quark\Obsidian笔记\Inbox"

$moved = 0
Get-ChildItem $Downloads -Filter "*.html" | ForEach-Object {
    $dest = Join-Path $Inbox $_.Name
    Move-Item $_.FullName -Destination $dest -Force
    Write-Output "→ $($_.Name)"
    $moved++
}

if ($moved -eq 0) {
    Write-Output "No HTML files found in Downloads"
} else {
    Write-Output "Done: $moved file(s) moved to Inbox"
}

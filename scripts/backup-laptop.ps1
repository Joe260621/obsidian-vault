# Claude Project Backup — Laptop Edition
# Excludes OCR intermediate PNGs (2.4GB, regeneratable) and node_modules
# Usage: .\backup-laptop.ps1 [-Dest <path>]  (default: .\backup-laptop\)
param(
    [string]$Dest = "$PSScriptRoot\..\backup-laptop"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "$PSScriptRoot\.."

Write-Output "=== Claude Project Backup (Laptop Edition) ==="
Write-Output "Source: $ProjectRoot"
Write-Output "Dest: $Dest"
Write-Output ""

if (Test-Path $Dest) {
    Remove-Item -Recurse -Force $Dest
}
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# 1. CLAUDE.md
Copy-Item "$ProjectRoot\CLAUDE.md" "$Dest\" -Force
Write-Output "[OK] CLAUDE.md"

# 2. Skills
$skillsDest = "$Dest\.claude\skills"
New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
Get-ChildItem "$ProjectRoot\.claude\skills" -Directory | ForEach-Object {
    Copy-Item $_.FullName -Destination "$skillsDest\" -Recurse -Force
}
Write-Output "[OK] .claude/skills/"

# 3. Settings + hooks + cron
Copy-Item "$ProjectRoot\.claude\settings.json" "$Dest\.claude\" -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\.claude\settings.local.json" "$Dest\.claude\" -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\.claude\hooks" -Destination "$Dest\.claude\hooks" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\.claude\scheduled_tasks.json" "$Dest\.claude\" -Force -ErrorAction SilentlyContinue
Write-Output "[OK] .claude/ settings + hooks + cron"

# 4. Wiki (exclude _ocr_pages intermediate PNGs — 2.4GB, regeneratable)
New-Item -ItemType Directory -Force -Path "$Dest\wiki" | Out-Null
Get-ChildItem "$ProjectRoot\wiki" -Directory | ForEach-Object {
    Copy-Item $_.FullName -Destination "$Dest\wiki\" -Recurse -Force
}
Get-ChildItem "$ProjectRoot\wiki" -File | ForEach-Object {
    Copy-Item $_.FullName -Destination "$Dest\wiki\" -Force
}
# Delete _ocr_pages from destination (Chinese path: use Remove-Item directly)
$ocrPagesPath = Join-Path $Dest "wiki\考编\_extracted\_ocr_pages"
if (Test-Path $ocrPagesPath) {
    Remove-Item -Recurse -Force $ocrPagesPath
    Write-Output "[OK] wiki/ (excluded _ocr_pages/)"
} else {
    Write-Output "[OK] wiki/ (_ocr_pages not found — OK)"
}

# 5. Raw
Copy-Item "$ProjectRoot\raw" -Destination "$Dest\raw" -Recurse -Force
Write-Output "[OK] raw/"

# 6. Scripts (without node_modules)
Get-ChildItem "$ProjectRoot\scripts" -Directory | Where-Object { $_.Name -ne 'node_modules' } | ForEach-Object {
    Copy-Item $_.FullName -Destination "$Dest\scripts\" -Recurse -Force -ErrorAction SilentlyContinue
}
Get-ChildItem "$ProjectRoot\scripts" -File | ForEach-Object {
    Copy-Item $_.FullName -Destination "$Dest\scripts\" -Force -ErrorAction SilentlyContinue
}
Write-Output "[OK] scripts/ (without node_modules)"

# 7. Docs
if (Test-Path "$ProjectRoot\docs") {
    Copy-Item "$ProjectRoot\docs" -Destination "$Dest\docs" -Recurse -Force
    Write-Output "[OK] docs/"
}

# 8. Daily notes
if (Test-Path "$ProjectRoot\daily") {
    Copy-Item "$ProjectRoot\daily" -Destination "$Dest\daily" -Recurse -Force
    Write-Output "[OK] daily/"
}

# 9. Archive
if (Test-Path "$ProjectRoot\archive") {
    Copy-Item "$ProjectRoot\archive" -Destination "$Dest\archive" -Recurse -Force
    Write-Output "[OK] archive/"
}

# 10. Memory
$memorySrc = "$env:USERPROFILE\.claude\projects\g--Claude\memory"
if (Test-Path $memorySrc) {
    Copy-Item $memorySrc -Destination "$Dest\memory" -Recurse -Force
    Write-Output "[OK] memory/"
}

# 11. Progress tracking
Copy-Item "$ProjectRoot\progress.md" "$Dest\" -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\TODO.md" "$Dest\" -Force -ErrorAction SilentlyContinue
Write-Output "[OK] progress.md + TODO.md"

# 12. Env file
Copy-Item "$ProjectRoot\.env" "$Dest\" -Force -ErrorAction SilentlyContinue
Write-Output "[OK] .env"

# Generate manifest
$size = [math]::Round((Get-ChildItem $Dest -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
$manifest = @"
# Claude Project Backup Manifest (Laptop Edition)
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source: $ProjectRoot
Total size: $size MB

## Excluded from this backup:
- wiki/考编/_extracted/_ocr_pages/ (2.4GB OCR intermediate PNGs — regeneratable)
- scripts/node_modules/ (67MB — run npm install on laptop)

## To restore on laptop:
1. Copy backup-laptop/ folder to laptop
2. Place contents in project root (e.g. G:\Claude\)
3. memory/ → %USERPROFILE%\.claude\projects\g--Claude\memory\
4. .claude/ → project root
5. Run: cd scripts && npm install (for OCR scripts)
6. Open Claude, say "初始化"
"@
$manifest | Out-File -FilePath "$Dest\MANIFEST.md" -Encoding utf8

Write-Output ""
Write-Output "=== Backup Complete ==="
Write-Output "Size: $size MB"
Write-Output "Location: $Dest"
Write-Output "To laptop: compress backup-laptop/ → transfer → extract to project root"

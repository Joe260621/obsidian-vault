# Claude Project Backup Script
# Usage: .\backup.ps1 [-Dest <path>]  (default: .\backup\)
# Copies all essential project files for cross-computer migration

param(
    [string]$Dest = "$PSScriptRoot\..\backup"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "$PSScriptRoot\.."

Write-Output "=== Claude Project Backup ==="
Write-Output "Source: $ProjectRoot"
Write-Output "Dest: $Dest"
Write-Output ""

# Remove old backup
if (Test-Path $Dest) {
    Remove-Item -Recurse -Force $Dest
}
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# 1. CLAUDE.md (core project instructions)
Copy-Item "$ProjectRoot\CLAUDE.md" "$Dest\" -Force
Write-Output "[OK] CLAUDE.md"

# 2. Skills (all custom skills)
$skillsSrc = "$ProjectRoot\.claude\skills"
$skillsDest = "$Dest\.claude\skills"
New-Item -ItemType Directory -Force -Path $skillsDest | Out-Null
# Copy all skill directories EXCEPT node_modules if any
Get-ChildItem $skillsSrc -Directory | Where-Object { $_.Name -ne 'node_modules' } | ForEach-Object {
    Copy-Item $_.FullName -Destination "$skillsDest\" -Recurse -Force
}
Write-Output "[OK] .claude/skills/"

# 3. Settings (permissions, hooks, etc.)
Copy-Item "$ProjectRoot\.claude\settings.json" "$Dest\.claude\" -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\.claude\settings.local.json" "$Dest\.claude\" -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\.claude\hooks" -Destination "$Dest\.claude\hooks" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\.claude\scheduled_tasks.json" "$Dest\.claude\" -Force -ErrorAction SilentlyContinue
Write-Output "[OK] .claude/ settings + hooks"

# 4. Wiki + Raw (knowledge base)
Copy-Item "$ProjectRoot\wiki" -Destination "$Dest\wiki" -Recurse -Force
Copy-Item "$ProjectRoot\raw" -Destination "$Dest\raw" -Recurse -Force
Write-Output "[OK] wiki/ + raw/"

# 5. Scripts (utility scripts)
Get-ChildItem "$ProjectRoot\scripts" -Directory | Where-Object { $_.Name -ne 'node_modules' } | ForEach-Object {
    Copy-Item $_.FullName -Destination "$Dest\scripts\" -Recurse -Force -ErrorAction SilentlyContinue
}
Get-ChildItem "$ProjectRoot\scripts" -File | ForEach-Object {
    Copy-Item $_.FullName -Destination "$Dest\scripts\" -Force -ErrorAction SilentlyContinue
}
Write-Output "[OK] scripts/ (without node_modules)"

# 6. Docs
if (Test-Path "$ProjectRoot\docs") {
    Copy-Item "$ProjectRoot\docs" -Destination "$Dest\docs" -Recurse -Force
    Write-Output "[OK] docs/"
}

# 7. Daily notes
if (Test-Path "$ProjectRoot\daily") {
    Copy-Item "$ProjectRoot\daily" -Destination "$Dest\daily" -Recurse -Force
    Write-Output "[OK] daily/"
}

# 8. Archive
if (Test-Path "$ProjectRoot\archive") {
    Copy-Item "$ProjectRoot\archive" -Destination "$Dest\archive" -Recurse -Force
    Write-Output "[OK] archive/"
}

# 9. Memory (cross-session persistent memory)
$memorySrc = "$env:USERPROFILE\.claude\projects\g--Claude\memory"
$memoryDest = "$Dest\memory"
if (Test-Path $memorySrc) {
    Copy-Item $memorySrc -Destination $memoryDest -Recurse -Force
    Write-Output "[OK] memory/"
}

# Generate manifest
$manifest = @"
# Claude Project Backup Manifest
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Source: $ProjectRoot

## To restore on another computer:
1. Copy the entire backup/ folder to the target machine
2. Place contents in your Claude project directory
3. .claude/ folder goes into your project root
4. memory/ goes into %USERPROFILE%\.claude\projects\<project-name>\memory\
5. Skills are auto-detected by Claude on next session start
"@
$manifest | Out-File -FilePath "$Dest\MANIFEST.md" -Encoding utf8

Write-Output ""
Write-Output "=== Backup Complete ==="
Write-Output "Location: $Dest"
Write-Output "To copy to another PC: compress backup/ folder and transfer"

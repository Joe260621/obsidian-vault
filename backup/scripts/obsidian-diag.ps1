# Obsidian diagnostic script
Write-Host "=== Shortcut Details ==="
$lnkPath = "C:\Users\YU\Desktop\Obsidian.lnk"
if (Test-Path $lnkPath) {
    $sh = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($lnkPath)
    Write-Host "Target:      $($lnk.TargetPath)"
    Write-Host "Arguments:   $($lnk.Arguments)"
    Write-Host "WorkingDir:  $($lnk.WorkingDirectory)"
    Write-Host "Icon:        $($lnk.IconLocation)"
} else {
    Write-Host "Obsidian.lnk not found on Desktop"
}

Write-Host ""
Write-Host "=== Search All Drives for Obsidian.exe ==="
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $root = $_.Root
    $found = Get-ChildItem -Path $root -Recurse -Filter 'Obsidian.exe' -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 5
    if ($found) { Write-Host "Found on $root : $($found.FullName)" }
}

Write-Host ""
Write-Host "=== Search for Obsidian appdata ==="
$paths = @(
    "$env:LOCALAPPDATA\Obsidian",
    "$env:LOCALAPPDATA\obsidian",
    "$env:APPDATA\Obsidian",
    "$env:APPDATA\obsidian",
    "C:\Program Files\Obsidian",
    "$env:USERPROFILE\scoop\apps\obsidian",
    "G:\Obsidian",
    "D:\Obsidian"
)
foreach ($p in $paths) {
    if (Test-Path $p) { Write-Host "EXISTS: $p" }
}

Write-Host ""
Write-Host "=== Obsidian Vault (.obsidian config) ==="
$vault = "G:\Claude\.obsidian"
if (Test-Path $vault) {
    Get-ChildItem $vault -Filter '*.json' | ForEach-Object {
        Write-Host "$($_.Name): $($_.Length) bytes, $($_.LastWriteTime)"
    }
}

Write-Host ""
Write-Host "=== Check Windows Event Log for Obsidian crash ==="
Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddHours(-3)} -MaxEvents 50 -ErrorAction SilentlyContinue | Where-Object { $_.Message -like '*Obsidian*' -or $_.Message -like '*obsidian*' } | Select-Object -First 5 TimeCreated, Id, @{N='Msg';E={$_.Message.Substring(0, [Math]::Min(200, $_.Message.Length))}}

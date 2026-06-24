# Crash diagnostic script
$ErrorActionPreference = "Stop"

Write-Host "=== Kernel-Power Event 41 ==="
try {
    $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=(Get-Date).AddHours(-2)} -MaxEvents 1 -ErrorAction Stop
    $xml = [xml]$e.ToXml()
    foreach ($d in $xml.Event.EventData.Data) {
        Write-Host "$($d.Name): $($d.'#text')"
    }
} catch { Write-Host "No Kernel-Power 41 found: $_" }

Write-Host ""
Write-Host "=== Bugcheck Reports ==="
try {
    $bugs = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; StartTime=(Get-Date).AddHours(-2)} -MaxEvents 3 -ErrorAction Stop
    foreach ($b in $bugs) {
        Write-Host "--- $($b.TimeCreated) ---"
        Write-Host $b.Message.Substring(0, [Math]::Min(500, $b.Message.Length))
    }
} catch { Write-Host "No bugcheck reports: $_" }

Write-Host ""
Write-Host "=== Recent Critical+Error in System log (last 2h) ==="
$events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddHours(-2)} -MaxEvents 10 -ErrorAction SilentlyContinue
foreach ($ev in $events) {
    $msg = $ev.Message -replace "`n", " " -replace "`r", ""
    if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 200) + "..." }
    Write-Host "[$($ev.TimeCreated)] ID=$($ev.Id) $($ev.LevelDisplayName) — $($ev.ProviderName): $msg"
}

Write-Host ""
Write-Host "=== Application Crashes Before Shutdown ==="
$ac = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-1).AddMinutes(-30), (Get-Date).AddHours(-1) } -MaxEvents 10 -ErrorAction SilentlyContinue
foreach ($a in $ac) {
    $x = [xml]$a.ToXml()
    $app = ""; $mod = ""; $ex = ""
    foreach ($d in $x.Event.EventData.Data) {
        if ($d.Name -eq "FaultingApplicationName") { $app = $d.'#text' }
        if ($d.Name -eq "FaultingModuleName") { $mod = $d.'#text' }
        if ($d.Name -eq "ExceptionCode") { $ex = $d.'#text' }
    }
    if ($app) { Write-Host "[$($a.TimeCreated)] App=$app Module=$mod Exception=$ex" }
}
if (-not $ac) { Write-Host "No application crashes found in that window" }

Write-Host ""
Write-Host "=== Recent DCOM Errors ==="
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-DistributedCOM'; Level=1,2; StartTime=(Get-Date).AddHours(-2)} -MaxEvents 3 -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "[$($_.TimeCreated)] $($_.Message.Substring(0, [Math]::Min(200, $_.Message.Length)))"
}

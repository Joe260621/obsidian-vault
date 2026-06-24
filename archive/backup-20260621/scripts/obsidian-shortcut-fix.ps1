# Fix Obsidian shortcut to include --disable-gpu flag
$lnkPath = "C:\Users\YU\Desktop\Obsidian.lnk"
$sh = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut($lnkPath)

Write-Host "Current shortcut:"
Write-Host "  Target: $($lnk.TargetPath)"
Write-Host "  Args:   $($lnk.Arguments)"

# Update to include --disable-gpu flag
$lnk.Arguments = "--disable-gpu"
$lnk.Save()

Write-Host ""
Write-Host "Updated shortcut:"
Write-Host "  Target: G:\Obsidian\Obsidian.exe"
Write-Host "  Args:   --disable-gpu"
Write-Host "Done. Shortcut fixed."

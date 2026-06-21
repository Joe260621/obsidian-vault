# Daily Check Script v4 - site monitor + jisilu QDII data + small-lot arb
$cookie = "kbzw__user_login=7Obd08_P1ebax9aXwZerl66tq6qRooKvpuXK7N_u0ejF1dSeqJGplK3b18qtoKmT2Jfcq9aultaVpqunmrLRsMetlqiYrqXW2cXS1qCbq52umqiUmLKgubXOvp-qrKGqo66UqpmomK6ltrG_0aTC2PPV487XkKylo5iJx8ri3eTg7IzFtpaSp6Wjs4HHyuKvqaSZ5K2Wn4G45-PkxsfG1sTe3aihqpmklK2Xm8OpxK7ApZXV4tfcgr3G2uLioYGzyebo4s6onauWpJGlp6GogcPC2trn0qihqpmklK2XxO3C4szEvKSfp6Wlk6SZra8."

function Check-Site {
    param($Name, $Url, $Keywords)
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 15
        $text = ($resp.Content -replace '<script[^>]*>.*?</script>', '') -replace '<style[^>]*>.*?</style>', ''
        $text = $text -replace '<[^>]+>', ' ' -replace '\s+', ' '
        if ($text.Length -lt 1000) {
            return [PSCustomObject]@{ Site = $Name; Status = "UP(SPA)"; Detail = "(JS-Rendered)" }
        }
        $found = @()
        foreach ($kw in $Keywords) { if ($text -match $kw) { $found += $kw } }
        return [PSCustomObject]@{ Site = $Name; Status = "UP"; Detail = if ($found.Count -gt 0) { ($found -join ', ') } else { "-" } }
    } catch {
        return [PSCustomObject]@{ Site = $Name; Status = "DOWN"; Detail = $_.Exception.Message.Substring(0, [Math]::Min(100, $_.Exception.Message.Length)) }
    }
}

# === Site Status ===
$all = @()
$all += Check-Site -Name "QGSYDW" -Url "https://www.qgsydw.com/qgsydw/index.html" -Keywords @('guangzhou','haizhu')
$all += Check-Site -Name "BOSS-ZP" -Url "https://www.zhipin.com/guangzhou/" -Keywords @('yunying','huiyuan')
$all += Check-Site -Name "JSL-QDII" -Url "https://www.jisilu.cn/data/qdii/" -Keywords @('161128','501225','yijia')
$all += Check-Site -Name "DS-Usage" -Url "https://platform.deepseek.com/usage" -Keywords @('token')

Write-Output "=== Daily Monitor $(Get-Date -Format 'yyyy-MM-dd HH:mm') ==="
$all | Format-Table -AutoSize

# === Jisilu QDII Data ===
Write-Output "`n=== QDII Arbitrage ==="
try {
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.Cookies.SetCookies("https://www.jisilu.cn", $cookie)
    $headers = @{
        "Accept" = "application/json, text/javascript, */*; q=0.01"
        "Referer" = "https://www.jisilu.cn/data/qdii/"
        "X-Requested-With" = "XMLHttpRequest"
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }
    $resp = Invoke-RestMethod -Uri "https://www.jisilu.cn/data/qdii/qdii_list/E?rp=100" -WebSession $session -Headers $headers -TimeoutSec 10

    # Calculate premium for all funds
    $allFunds = @()
    foreach ($row in $resp.rows) {
        $c = $row.cell
        $premVal = 0
        if ($c.discount_rt -and $c.discount_rt -ne '-') {
            $tmp = ($c.discount_rt -replace '%','').Trim()
            [double]::TryParse($tmp, [ref]$premVal) | Out-Null
        } elseif ($c.fund_nav -and $c.price -and [double]$c.fund_nav -ne 0) {
            $premVal = [math]::Round(([double]$c.price / [double]$c.fund_nav - 1) * 100, 2)
        }
        $allFunds += [PSCustomObject]@{
            Id = $c.fund_id
            Name = $c.fund_nm
            Price = $c.price
            Nav = $c.fund_nav
            NavDate = $c.nav_dt
            Prem = $premVal
            Apply = $c.apply_status
            Amount = $c.amount_incr
        }
    }

    # --- Target Funds ---
    Write-Output "--- Target ---"
    foreach ($f in $allFunds) {
        if ($f.Id -eq '161128' -or $f.Id -eq '501225' -or $f.Id -eq '164824') {
            Write-Output ("{0} {1} prem={2}% apply={3}" -f $f.Id, $f.Name, $f.Prem, $f.Apply)
        }
    }

    # --- Top 5 Premium ---
    Write-Output "`n--- Top 5 Premium ---"
    $allFunds | Sort-Object Prem -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Output ("{0} {1} prem={2}% apply={3}" -f $_.Id, $_.Name, $_.Prem, $_.Apply)
    }

    # --- Small-Lot Arb: open, premium > 2%, apply contains "100"/"500"/"1" or is open ---
    Write-Output "`n--- Small-Lot Arb ---"
    $small = $allFunds | Where-Object {
        $_.Prem -gt 2 -and $_.Apply -ne "zan ting shen gou" -and $_.Apply -ne $null -and $_.Apply -ne ""
    } | Sort-Object Prem -Descending
    if ($small.Count -gt 0) {
        # Highlight those with explicit small limits
        foreach ($f in $small) {
            $badge = ""
            if ($f.Apply -match '100') { $badge = "[100]" }
            elseif ($f.Apply -match '500') { $badge = "[500]" }
            elseif ($f.Apply -match '1qian|yi qian|1000') { $badge = "[1K]" }
            Write-Output ("{0}{1} {2} prem={3}% apply={4}" -f $badge, $f.Id, $f.Name, $f.Prem, $f.Apply)
        }
    } else {
        Write-Output "No high-premium open funds today."
    }

} catch {
    Write-Output ("QDII API FAILED: " + $_.Exception.Message.Substring(0, 80))
}

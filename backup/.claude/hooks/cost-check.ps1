# cost-check.ps1 — 手动检查当前或所有会话的 token 消耗
# 用法:
#   .\cost-check.ps1              检查最近会话
#   .\cost-check.ps1 -All         显示今天所有会话
#   .\cost-check.ps1 -SessionId xxx  检查指定会话

param(
    [switch]$All,
    [string]$SessionId = ""
)

$transcriptDir = "$env:USERPROFILE\.claude\projects\g--Claude"

function Analyze-Session($jsonlPath) {
    if (-not (Test-Path $jsonlPath)) { return $null }

    $turnCount = 0
    $inputTokens = 0
    $outputTokens = 0
    $cacheRead = 0
    $cacheCreate = 0
    $model = "unknown"

    Get-Content $jsonlPath -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        if (-not $line) { return }
        try { $rec = $line | ConvertFrom-Json } catch { return }
        if ($rec.type -eq "assistant") {
            $usage = $rec.message.usage
            if ($usage) {
                $turnCount++
                $inputTokens += [long]($usage.input_tokens -as [long])
                $outputTokens += [long]($usage.output_tokens -as [long])
                $cr = [long]($usage.cache_read_input_tokens -as [long])
                $cacheRead += $cr
                if ($usage.cache_creation) {
                    $cacheCreate += [long]($usage.cache_creation.ephemeral_1h_input_tokens -as [long])
                    $cacheCreate += [long]($usage.cache_creation.ephemeral_5m_input_tokens -as [long])
                }
                if ($rec.message.model) { $model = $rec.message.model }
            }
        }
    }

    $cost = ($inputTokens/1e6)*1.0 + ($outputTokens/1e6)*4.0 +
            ($cacheRead/1e6)*0.1 + ($cacheCreate/1e6)*1.0

    return [PSCustomObject]@{
        File = Split-Path $jsonlPath -Leaf
        Turns = $turnCount
        Input = $inputTokens
        Output = $outputTokens
        CacheRead = $cacheRead
        CostCNY = [math]::Round($cost, 2)
        Model = $model
        LastWrite = (Get-Item $jsonlPath).LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    }
}

if ($SessionId) {
    $jsonlPath = Join-Path $transcriptDir "$SessionId.jsonl"
    $r = Analyze-Session $jsonlPath
    if ($r) {
        Write-Output ""
        Write-Output "=== 会话: $SessionId ==="
        Write-Output "  轮次: $($r.Turns)"
        Write-Output "  输入: $('{0:N0}' -f $r.Input) tokens"
        Write-Output "  输出: $('{0:N0}' -f $r.Output) tokens"
        Write-Output "  缓存读取: $('{0:N0}' -f $r.CacheRead) tokens"
        Write-Output "  费用估算: CNY $($r.CostCNY)"
        Write-Output "  模型: $($r.Model)"
        Write-Output "  最后更新: $($r.LastWrite)"
    } else {
        Write-Output "未找到会话: $SessionId"
    }
    exit 0
}

# 默认：显示今天所有会话 + 总计
$today = Get-Date -Format "yyyy-MM-dd"
$files = Get-ChildItem $transcriptDir -Filter "*.jsonl" |
         Where-Object { $_.LastWriteTime.ToString("yyyy-MM-dd") -eq $today } |
         Sort-Object LastWriteTime

if (-not $files) {
    Write-Output "今天暂无会话记录"
    exit 0
}

$grandCost = 0
$grandTurns = 0

Write-Output ""
Write-Output "=== $(Get-Date -Format 'yyyy-MM-dd') Token 消耗报告 ==="
Write-Output ""
Write-Output "  SessionID   Turns     InputTokens  OutputTokens  CacheRead    Cost(CNY)  LastUpdate"
Write-Output "  ---------   -----     -----------  ------------  ---------    ---------  ----------"

foreach ($f in $files) {
    $r = Analyze-Session $f.FullName
    if ($r) {
        $sid = $r.File.Replace(".jsonl", "").Substring(0, [Math]::Min(8, $r.File.Length-5))
        Write-Output "  ${sid}...  $($r.Turns)  $('{0:N0}' -f $r.Input)  $('{0:N0}' -f $r.Output)  $('{0:N0}' -f $r.CacheRead)  $($r.CostCNY)  $($r.LastWrite)"
        $grandCost += $r.CostCNY
        $grandTurns += $r.Turns
    }
}

Write-Output ""
Write-Output "总计: ${grandTurns} 轮, CNY $([math]::Round($grandCost, 2))"
Write-Output ""
if ($grandCost -gt 10) {
    Write-Output "WARNING: 今日总费用已超过 CNY 10，建议检查是否有超长会话。"
}
if ($grandCost -gt 20) {
    Write-Output "CRITICAL: 今日总费用已超过 CNY 20！请立即检查 CLAUDE.md 规则15-20 是否被遵守。"
}

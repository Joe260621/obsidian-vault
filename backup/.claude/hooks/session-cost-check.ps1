# session-cost-check.ps1
# 检查当前会话的 token 消耗，超过阈值时输出警告
# 用法: powershell -File session-cost-check.ps1 -SessionId <uuid>

param(
    [string]$SessionId = ""
)

$ErrorActionPreference = "SilentlyContinue"
$transcriptDir = "$env:USERPROFILE\.claude\projects\g--Claude"

if (-not $SessionId) {
    # 尝试从环境变量或最近修改的文件推断
    $latest = Get-ChildItem $transcriptDir -Filter "*.jsonl" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) { $SessionId = $latest.BaseName }
}

if (-not $SessionId) { exit 0 }

$jsonlPath = Join-Path $transcriptDir "$SessionId.jsonl"
if (-not (Test-Path $jsonlPath)) { exit 0 }

# 解析统计数据
$turnCount = 0
$inputTokens = 0
$outputTokens = 0
$cacheRead = 0
$cacheCreate = 0
$model = "unknown"

Get-Content $jsonlPath -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if (-not $line) { return }
    try {
        $rec = $line | ConvertFrom-Json
    } catch { return }

    if ($rec.type -eq "assistant") {
        $usage = $rec.message.usage
        if ($usage) {
            $turnCount++
            $inputTokens += [long]($usage.input_tokens -as [long])
            $outputTokens += [long]($usage.output_tokens -as [long])
            $cr = [long]($usage.cache_read_input_tokens -as [long])
            $cacheRead += $cr

            # 缓存创建 token 可能在子对象中
            $cc = [long]($usage.cache_creation_input_tokens -as [long])
            if ($usage.cache_creation) {
                $cc += [long]($usage.cache_creation.ephemeral_1h_input_tokens -as [long])
                $cc += [long]($usage.cache_creation.ephemeral_5m_input_tokens -as [long])
            }
            $cacheCreate += $cc

            if ($rec.message.model) { $model = $rec.message.model }
        }
    }
}

# DeepSeek v4 定价 (CNY/百万 tokens)
$priceInput = 1.0
$priceOutput = 4.0
$priceCacheRead = 0.1
$priceCacheWrite = 1.0

$cost = ($inputTokens/1e6)*$priceInput + ($outputTokens/1e6)*$priceOutput +
        ($cacheRead/1e6)*$priceCacheRead + ($cacheCreate/1e6)*$priceCacheWrite

$totalTokens = $inputTokens + $outputTokens + $cacheRead + $cacheCreate

# 阈值定义
$warnTurnThreshold = 30    # 黄色预警
$critTurnThreshold = 50    # 红色预警 → 强制执行分段规则
$warnCostThreshold = 3.0   # 费用黄色预警
$critCostThreshold = 8.0   # 费用红色预警

$level = "OK"
$warnings = @()

if ($turnCount -ge $critTurnThreshold) {
    $level = "CRIT"
    $warnings += "[CRIT] 会话已超 ${critTurnThreshold} 轮 (${turnCount} 轮) — CLAUDE.md 规则15: 必须提议分段"
} elseif ($turnCount -ge $warnTurnThreshold) {
    $level = "WARN"
    $warnings += "[WARN] 会话已有 ${turnCount} 轮 — CLAUDE.md 规则20: 提醒用户分段"
}

if ($cost -ge $critCostThreshold) {
    $level = "CRIT"
    $warnings += "[CRIT] 当前会话已花费 CNY $('{0:F2}' -f $cost) — 超过 ¥${critCostThreshold} 红线"
} elseif ($cost -ge $warnCostThreshold) {
    if ($level -ne "CRIT") { $level = "WARN" }
    $warnings += "[WARN] 当前会话已花费 CNY $('{0:F2}' -f $cost)"
}

# 输出 JSON 格式供 Claude 读取
$result = [PSCustomObject]@{
    sessionId = $SessionId
    model = $model
    turns = $turnCount
    inputTokens = $inputTokens
    outputTokens = $outputTokens
    cacheReadTokens = $cacheRead
    cacheCreateTokens = $cacheCreate
    totalTokens = $totalTokens
    estimatedCostCNY = [math]::Round($cost, 2)
    level = $level
    warnings = $warnings -join "; "
    message = if ($level -eq "CRIT") {
        "⛔ 成本红线! $($warnings -join ' | ')"
    } elseif ($level -eq "WARN") {
        "⚠️ 成本预警: $($warnings -join ' | ')"
    } else { "" }
}

# 输出到 stdout (Claude 会看到)
if ($level -ne "OK") {
    Write-Output $result.message
}

# 同时写入状态文件供查询
$stateFile = Join-Path $transcriptDir ".cost-state-$SessionId.json"
$result | ConvertTo-Json -Compress | Out-File $stateFile -Encoding UTF8

exit 0

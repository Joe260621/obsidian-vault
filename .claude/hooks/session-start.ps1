# Superpowers SessionStart hook (Windows PowerShell version)
# Injects using-superpowers skill content AND cost awareness at session start

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginRoot = Split-Path -Parent $scriptDir
$skillsDir = Join-Path $pluginRoot "skills"
$skillFile = Join-Path $skillsDir "using-superpowers" "SKILL.md"

$skillContent = Get-Content $skillFile -Raw -ErrorAction SilentlyContinue
if (-not $skillContent) { exit 0 }

# Escape for JSON
$escaped = $skillContent -replace '\\', '\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", '\r' -replace "`t", '\t'

# === Cost check: analyze current session transcript ===
$costWarning = ""
# 聚合三个项目目录的 jsonl（与 cost-check.ps1 保持一致）
$projectsDir = "$env:USERPROFILE\.claude\projects"
$transcriptDirs = @(
    "$projectsDir\d-------AI",
    "$projectsDir\d--ProjectManagement-AI",
    "$projectsDir\d-------Claude--"
)
$sessionId = $env:CLAUDE_SESSION_ID  # may not be set

if ($sessionId) {
    # 跨三个项目目录查找当前会话的 jsonl
    $jsonlPath = $null
    foreach ($dir in $transcriptDirs) {
        $candidate = Join-Path $dir "$sessionId.jsonl"
        if (Test-Path $candidate) { $jsonlPath = $candidate; break }
    }
    if ($jsonlPath) {
        $turnCount = 0
        $cacheRead = 0
        $outputTokens = 0
        $inputTokens = 0

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
                    $cacheRead += [long]($usage.cache_read_input_tokens -as [long])
                }
            }
        }

        $cost = ($inputTokens/1e6)*1.0 + ($outputTokens/1e6)*4.0 + ($cacheRead/1e6)*0.1

        if ($turnCount -ge 50) {
            $costWarning = "COST ALERT: 当前会话已达 ${turnCount} 轮，已花费约 CNY $([math]::Round($cost,2))。根据 CLAUDE.md 规则15，必须主动提议分段。"
        } elseif ($turnCount -ge 30) {
            $costWarning = "COST NOTE: 当前会话已 ${turnCount} 轮，已花费约 CNY $([math]::Round($cost,2))。根据 CLAUDE.md 规则20，适时提醒用户分段。"
        }
    }
}

$additionalContext = "<EXTREMELY_IMPORTANT>`nYou have superpowers.`n`n**Below is the full content of your 'superpowers:using-superpowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**`n`n${escaped}`n</EXTREMELY_IMPORTANT>"

if ($costWarning) {
    $additionalContext += "`n`n<EXTREMELY_IMPORTANT>`n${costWarning}`n</EXTREMELY_IMPORTANT>"
}

$json = @"
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${additionalContext}"
  }
}
"@

Write-Output $json

# Send message to Feishu via bot API
param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$appId = "cli_aaa40aca3f789be8"
$appSecret = "eqT2nUmBj3TqN6IBrrIs8cRV0F2ZkH8j"
$chatId = "oc_7611b2f2e2a8273e0d61dcba7f89958c"

# Step 1: Get tenant access token
$tokenBody = @{ app_id = $appId; app_secret = $appSecret } | ConvertTo-Json -Compress
$tokenBytes = [System.Text.Encoding]::UTF8.GetBytes($tokenBody)

try {
    $tokenResp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" `
        -Method Post `
        -ContentType "application/json; charset=utf-8" `
        -Body $tokenBytes `
        -TimeoutSec 10
    $token = $tokenResp.tenant_access_token
} catch {
    Write-Output "ERROR: Failed to get Feishu token: $($_.Exception.Message)"
    exit 1
}

# Step 2: Send message
$textContent = @{ text = $Message } | ConvertTo-Json -Compress
$bodyObj = @{
    receive_id = $chatId
    msg_type   = "text"
    content    = $textContent
}
$bodyJson = $bodyObj | ConvertTo-Json -Compress
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

try {
    $resp = Invoke-RestMethod -Uri "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=chat_id" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $token" } `
        -ContentType "application/json; charset=utf-8" `
        -Body $bodyBytes `
        -TimeoutSec 10
    Write-Output "OK: message sent, msg_id=$($resp.data.message_id)"
} catch {
    Write-Output "ERROR: Failed to send message: $($_.Exception.Message)"
    exit 1
}

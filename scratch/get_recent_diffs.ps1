$logPath = "C:\Users\LENOVO\.gemini\antigravity\brain\5c617ef8-ad48-4adb-95da-ff1e01be0e47\.system_generated\logs\transcript.jsonl"
$lines = Get-Content $logPath
$codeActions = @()
foreach ($line in $lines) {
    if ($line -match '"type":"CODE_ACTION"') {
        try {
            $obj = ConvertFrom-Json $line
            $codeActions += $obj
        } catch {}
    }
}
$recent = $codeActions | Select-Object -Last 40
foreach ($act in $recent) {
    Write-Host "Created At: $($act.created_at)"
    Write-Host "Content:"
    Write-Host $act.content
    Write-Host "========================================"
}

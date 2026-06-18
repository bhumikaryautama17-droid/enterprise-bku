$content = Get-Content "C:\Users\LENOVO\.gemini\antigravity\brain\5c617ef8-ad48-4adb-95da-ff1e01be0e47\.system_generated\logs\transcript.jsonl"
$match = $content | Select-String -Pattern "function generatePDF\(requestId\)" -Context 0,200 | Select-Object -First 1
if ($match) {
    $match.Context.PostContext | Out-File scratch\generatePDF_backup.txt
    Write-Host "Backup found!"
} else {
    Write-Host "Not found"
}

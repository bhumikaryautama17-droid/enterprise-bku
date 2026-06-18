$lines = Get-Content "C:\Users\LENOVO\.gemini\antigravity\brain\5c617ef8-ad48-4adb-95da-ff1e01be0e47\.system_generated\logs\transcript.jsonl"
$matchLines = @()
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match "function generatePDF") {
        $matchLines += $i
    }
}
Write-Host "Found at lines: $($matchLines -join ', ')"
if ($matchLines.Length -gt 0) {
    $targetLine = $matchLines[0]
    $lines[$targetLine] | Out-File scratch\generatePDF_backup.txt
    Write-Host "Wrote first match to generatePDF_backup.txt"
}

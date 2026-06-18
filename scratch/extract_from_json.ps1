$lines = Get-Content "C:\Users\LENOVO\.gemini\antigravity\brain\5c617ef8-ad48-4adb-95da-ff1e01be0e47\.system_generated\logs\transcript.jsonl"
$jsonText = $lines[134]
$obj = ConvertFrom-Json $jsonText
$content = $obj.tool_calls[0].args.CodeContent
if (-not $content) { $content = $obj.tool_calls[0].args.ReplacementContent }
if (-not $content) { $content = $obj.content }
$content | Out-File "scratch\generatePDF_restored.txt" -Encoding UTF8
Write-Host "Restored! Length: $($content.Length)"

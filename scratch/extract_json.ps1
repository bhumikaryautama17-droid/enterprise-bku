$jsonText = Get-Content "scratch\generatePDF_backup.txt" -Raw
$jsonObj = $jsonText | ConvertFrom-Json
$content = ""
if ($jsonObj.content) { $content = $jsonObj.content }
elseif ($jsonObj.tool_calls[0].args.CodeContent) { $content = $jsonObj.tool_calls[0].args.CodeContent }
elseif ($jsonObj.tool_calls[0].args.ReplacementContent) { $content = $jsonObj.tool_calls[0].args.ReplacementContent }

$content | Out-File scratch\generatePDF_raw.txt
Write-Host "Extracted raw content. Length: $($content.Length)"

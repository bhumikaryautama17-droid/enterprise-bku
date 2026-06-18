$jsonText = Get-Content "scratch\generatePDF_raw.txt" -Raw
$jsonObj = $jsonText | ConvertFrom-Json
$content = $jsonObj.tool_calls[0].args.CodeContent
$content | Out-File scratch\generatePDF_raw2.txt

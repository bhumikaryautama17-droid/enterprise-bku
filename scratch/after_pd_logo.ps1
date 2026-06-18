$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)

$idx = 337184
# Find the end of the base64 string starting at $idx
# We know the base64 starts at $idx and has length 151207.
$endIdx = $idx + 151207
$out = $content.Substring($endIdx, [Math]::Min(1000, $content.Length - $endIdx))

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\after_pd_logo.txt" -Encoding utf8
Write-Host "Done"

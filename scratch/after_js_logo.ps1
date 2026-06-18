$f = "JavaScript.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)

$idx = 99485
# Find the end of the base64 string starting at $idx
$endIdx = $idx + 151207
$out = $content.Substring($endIdx, [Math]::Min(1000, $content.Length - $endIdx))

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\after_js_logo.txt" -Encoding utf8
Write-Host "Done"

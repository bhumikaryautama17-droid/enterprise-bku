$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)

$idx = 37942
$endIdx = $idx + 151207
$out = $content.Substring($endIdx, [Math]::Min(1000, $content.Length - $endIdx))

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\after_pd_paper_logo.txt" -Encoding utf8
Write-Host "Done"

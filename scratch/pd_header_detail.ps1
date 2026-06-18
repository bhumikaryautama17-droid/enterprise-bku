$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)

# Let's search for Match 4 in index_local_preview.html (Index 337184) and get 2000 characters around it.
$idx = 337184
$start = $idx - 500
$len = 2500
$out = $content.Substring($start, $len)

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\pd_header_detail.txt" -Encoding utf8
Write-Host "Done"

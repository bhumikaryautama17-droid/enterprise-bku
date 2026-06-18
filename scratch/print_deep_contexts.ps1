$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)
$out = @()

$idx3 = 308551
$out += "=== Match 3 Deep Context (Index $idx3) ==="
$start3 = $idx3 - 3000
$out += $content.Substring($start3, 3000)
$out += "===================================="

$idx4 = 337184
$out += "=== Match 4 Deep Context (Index $idx4) ==="
$start4 = $idx4 - 3000
$out += $content.Substring($start4, 3000)
$out += "===================================="

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\print_deep_contexts.txt" -Encoding utf8
Write-Host "Done"

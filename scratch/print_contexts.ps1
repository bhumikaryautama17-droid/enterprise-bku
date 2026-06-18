$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)
$out = @()

# We want to search for Match 3 (around index 308551) and Match 4 (around index 337184)
# Let's show 1000 characters before these indices to see what function or template they belong to.

$idx3 = 308551
$out += "=== Match 3 Context (Index $idx3) ==="
$start3 = [Math]::Max(0, $idx3 - 1000)
$out += $content.Substring($start3, 1000)
$out += "===================================="

$idx4 = 337184
$out += "=== Match 4 Context (Index $idx4) ==="
$start4 = [Math]::Max(0, $idx4 - 1000)
$out += $content.Substring($start4, 1000)
$out += "===================================="

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\print_contexts.txt" -Encoding utf8
Write-Host "Done"

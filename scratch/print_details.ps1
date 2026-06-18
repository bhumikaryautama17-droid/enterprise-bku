$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)
$out = @()

# We want to inspect the code around Match 3 (around index 308551) and Match 4 (around index 337184)
# with a window of 500 characters before and 200 characters after.

$idx3 = 308551
$out += "=== Match 3 Detail (Index $idx3) ==="
$start3 = $idx3 - 500
$len3 = 500 + 12890 + 200
$out += $content.Substring($start3, 500)
$out += " [BASE64 LOGO OF LENGTH 12890] "
$out += $content.Substring($idx3 + 12890, 200)
$out += "===================================="

$idx4 = 337184
$out += "=== Match 4 Detail (Index $idx4) ==="
$start4 = $idx4 - 500
$len4 = 500 + 12890 + 200
$out += $content.Substring($start4, 500)
$out += " [BASE64 LOGO OF LENGTH 12890] "
$out += $content.Substring($idx4 + 12890, 200)
$out += "===================================="

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\print_details.txt" -Encoding utf8
Write-Host "Done"

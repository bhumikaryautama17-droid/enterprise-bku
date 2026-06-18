$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    for ($i = 1640; $i -le 1675; $i++) {
        $out += "Line $($i): $($lines[$i-1])"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\initApp_range.txt" -Encoding utf8
Write-Host "Done"

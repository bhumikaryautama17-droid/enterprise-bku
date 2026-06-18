$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Stylesheet.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    for ($i = 560; $i -le 610; $i++) {
        $out += "Line $($i): $($lines[$i-1])"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\style_range_tables.txt" -Encoding utf8
Write-Host "Done"

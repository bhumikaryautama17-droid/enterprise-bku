$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Stylesheet.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    for ($i = 430; $i -le 480; $i++) {
        $out += "Line $($i): $($lines[$i-1])"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\style_range_out.txt" -Encoding utf8
Write-Host "Done"

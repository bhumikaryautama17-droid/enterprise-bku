$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Stylesheet.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    $i = 0
    foreach ($line in $lines) {
        $i++
        if ($line.Contains("panel-card") -or $line.Contains("paper") -or $line.Contains("modal-content")) {
            $out += "Line $($i): $($line.Trim())"
        }
    }
} else {
    $out += "Stylesheet.html not found!"
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\search_style_out.txt" -Encoding utf8
Write-Host "Done"

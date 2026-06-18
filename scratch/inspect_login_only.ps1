$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Stylesheet.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    $i = 0
    foreach ($line in $lines) {
        $i++
        if ($line.Contains("login")) {
            $out += "Line $($i): $($line.Trim())"
        }
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\search_login_only.txt" -Encoding utf8
Write-Host "Done"

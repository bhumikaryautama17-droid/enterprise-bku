$query = "login-page"
$files = @("Index.html", "index_local_preview.html")
$out = @()
foreach ($file in $files) {
    $path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$file"
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path)
        $lines = $content -split "\r?\n"
        $i = 0
        foreach ($line in $lines) {
            $i++
            if ($line.Contains($query)) {
                $out += "$file Line $($i): $($line.Trim())"
            }
        }
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\search_login_page.txt" -Encoding utf8
Write-Host "Done"

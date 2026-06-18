$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    for ($i = 120; $i -le 180; $i++) {
        $out += "Line $($i): $($lines[$i-1])"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\header_index_range.txt" -Encoding utf8
Write-Host "Done"

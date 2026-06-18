$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $lines = $content -split "\r?\n"
    for ($i = 1; $i -le 45; $i++) {
        $out += "Line $($i): $($lines[$i-1])"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\head_preview_out.txt" -Encoding utf8
Write-Host "Done"

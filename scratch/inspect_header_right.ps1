$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    # Search for header-right or bell icon
    $idx = $content.IndexOf("header-right")
    if ($idx -ge 0) {
        $out += "Found header-right at index $idx"
        $out += $content.Substring($idx, 600)
    } else {
        $out += "header-right not found in Index.html"
    }
} else {
    $out += "Index.html not found!"
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\header_right_out.txt" -Encoding utf8
Write-Host "Done"

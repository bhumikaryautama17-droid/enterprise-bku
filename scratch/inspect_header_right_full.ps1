$pathIndex = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html"
$pathPreview = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$out = @()

if (Test-Path $pathIndex) {
    $content = [System.IO.File]::ReadAllText($pathIndex)
    $idx = $content.IndexOf("class=""header-right""")
    if ($idx -lt 0) { $idx = $content.IndexOf("header-right") }
    if ($idx -ge 0) {
        $out += "=== Index.html header-right ==="
        $out += $content.Substring($idx, 1500)
    }
}

if (Test-Path $pathPreview) {
    $content = [System.IO.File]::ReadAllText($pathPreview)
    $idx = $content.IndexOf("class=""header-right""")
    if ($idx -lt 0) { $idx = $content.IndexOf("header-right") }
    if ($idx -ge 0) {
        $out += "=== index_local_preview.html header-right ==="
        $out += $content.Substring($idx, 1500)
    }
}

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\header_right_full.txt" -Encoding utf8
Write-Host "Done"

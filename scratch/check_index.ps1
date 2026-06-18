$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $matches = [regex]::Matches($content, 'data:image\/[a-zA-Z]+;base64,[A-Za-z0-9+/=\s\r\n]+')
    $out += "Total matches in Index.html: $($matches.Count)"
    $i = 0
    foreach ($m in $matches) {
        $i++
        $out += "Match $i at Index $($m.Index) Length: $($m.Length)"
        $start = [Math]::Max(0, $m.Index - 150)
        $out += "  Context before: $($content.Substring($start, $m.Index - $start))"
        $out += "-----------------------------------------"
    }
} else {
    $out += "Index.html not found!"
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\check_index_out.txt" -Encoding utf8
Write-Host "Done"

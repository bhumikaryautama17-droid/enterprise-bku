$files = @("index_local_preview.html", "JavaScript.html", "Code.js")
$outFile = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\found_logos.txt"
$out = @()

foreach ($f in $files) {
    $path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path)
        $out += "=== File: $f ==="
        # Search for data:image/...base64
        $matches = [regex]::Matches($content, 'data:image\/[a-zA-Z]+;base64,[A-Za-z0-9+/=\s\r\n]+')
        $out += "Total base64 images found: $($matches.Count)"
        $i = 0
        foreach ($m in $matches) {
            $i++
            $start = [Math]::Max(0, $m.Index - 150)
            $len = [Math]::Min($content.Length - $start, $m.Length + 300)
            $context = $content.Substring($start, $len)
            
            $before = $content.Substring($start, $m.Index - $start)
            $val = $m.Value
            $valStart = $val.Substring(0, [Math]::Min(80, $val.Length))
            $valEnd = $val.Substring([Math]::Max(0, $val.Length - 80))
            $after = $content.Substring($m.Index + $m.Length, [Math]::Min(150, $content.Length - ($m.Index + $m.Length)))
            
            $out += "Match $i (Length: $($m.Length), Index: $($m.Index)):"
            $out += "Context before: $before"
            $out += "Base64 value: $valStart ... $valEnd"
            $out += "Context after: $after"
            $out += "-------------------------------------"
        }
    } else {
        $out += "File not found: $f"
    }
}

$out | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Done, results in $outFile"

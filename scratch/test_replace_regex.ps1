$files = @("index_local_preview.html", "Code.js")
$out = @()

foreach ($f in $files) {
    $path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path)
        $out += "=== File: $f ==="
        
        # Regex to find: <td style="width:25%; ... followed by <img src="data:image/png;base64, ...
        # Since there might be whitespace or line breaks, we allow \s* or \r?\n
        $pattern = '(<td style="width:25%; text-align:center; border:1px solid #111; padding:6px; vertical-align:middle;">\s*<img src=")(data:image/png;base64,iVBORw0KGgoAAA[A-Za-z0-9+/=\s\r\n]{12000,13000})(" style="max-height:95px;)'
        
        $matches = [regex]::Matches($content, $pattern)
        $out += "Pattern matches found: $($matches.Count)"
        $i = 0
        foreach ($m in $matches) {
            $i++
            $out += "  Match $i at index $($m.Index):"
            $out += "    Group 1 (HTML prefix): $($m.Groups[1].Value)"
            $out += "    Group 2 (Base64 start): $($m.Groups[2].Value.Substring(0, 100)) ... $($m.Groups[2].Value.Substring($m.Groups[2].Value.Length - 50))"
            $out += "    Group 3 (HTML suffix): $($m.Groups[3].Value)"
        }
        $out += "------------------------"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\regex_test_out.txt" -Encoding utf8
Write-Host "Done"

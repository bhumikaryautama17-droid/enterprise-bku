$files = @("index_local_preview.html", "JavaScript.html", "Code.js")
$out = @()

foreach ($f in $files) {
    $path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path)
        $out += "=== File: $f ==="
        # Search for occurrences of buildPaperHTML or buildPaperHTMLServer
        $matches = [regex]::Matches($content, 'function\s+[a-zA-Z0-9_]+\s*\(')
        foreach ($m in $matches) {
            $out += "Function match: $($m.Value) at index $($m.Index)"
        }
        $buildPaperHTMLMatches = [regex]::Matches($content, 'buildPaperHTML')
        foreach ($m in $buildPaperHTMLMatches) {
            $out += "buildPaperHTML occurrence at index $($m.Index)"
        }
        $buildPaperHTMLServerMatches = [regex]::Matches($content, 'buildPaperHTMLServer')
        foreach ($m in $buildPaperHTMLServerMatches) {
            $out += "buildPaperHTMLServer occurrence at index $($m.Index)"
        }
        $out += "------------------------"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\function_occurrences.txt" -Encoding utf8
Write-Host "Done"

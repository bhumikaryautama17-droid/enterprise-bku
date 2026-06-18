$f = "index_local_preview.html"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)
$matches = [regex]::Matches($content, 'data:image\/[a-zA-Z]+;base64,[A-Za-z0-9+/=\s\r\n]+')
$i = 0
$out = @()
foreach ($m in $matches) {
    $i++
    $out += "Match $i at Index $($m.Index) (Length: $($m.Length))"
    # Search backwards for '<div' or '<table' or 'id='
    $searchStart = [Math]::Max(0, $m.Index - 2000)
    $beforeText = $content.Substring($searchStart, $m.Index - $searchStart)
    
    # Try to find last occurred id= or paper container
    $lastIdMatch = [regex]::Matches($beforeText, 'id="[a-zA-Z0-9_-]+"')
    if ($lastIdMatch.Count -gt 0) {
        $lastId = $lastIdMatch[$lastIdMatch.Count - 1].Value
        $out += "  Last ID found before match: $lastId"
    } else {
        $out += "  No ID found within 2000 chars before"
    }
    
    $structStart = [Math]::Max(0, $m.Index - 350)
    $structBefore = $content.Substring($structStart, $m.Index - $structStart)
    $out += "  HTML context before: $structBefore"
    $out += "---------------------------------------------------"
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\parent_contexts.txt" -Encoding utf8
Write-Host "Done"

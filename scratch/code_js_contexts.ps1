$f = "Code.js"
$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$f"
$content = [System.IO.File]::ReadAllText($path)
$out = @()

$matches = [regex]::Matches($content, 'data:image\/[a-zA-Z]+;base64,[A-Za-z0-9+/=\s\r\n]+')
$i = 0
foreach ($m in $matches) {
    $i++
    $out += "Match $i at Index $($m.Index) (Length: $($m.Length))"
    
    # Show 500 characters before the match to see the HTML structure
    $structStart = [Math]::Max(0, $m.Index - 500)
    $structBefore = $content.Substring($structStart, $m.Index - $structStart)
    $out += "  Context before: $structBefore"
    
    # Show 200 characters after the match
    $structAfter = $content.Substring($m.Index + $m.Length, [Math]::Min(200, $content.Length - ($m.Index + $m.Length)))
    $out += "  Context after: $structAfter"
    $out += "---------------------------------------------------"
}

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\code_js_contexts.txt" -Encoding utf8
Write-Host "Done"

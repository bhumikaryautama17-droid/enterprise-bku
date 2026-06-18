$files = @("Index.html", "index_local_preview.html")
$out = @()

foreach ($file in $files) {
    $path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\$file"
    if (Test-Path $path) {
        $content = [System.IO.File]::ReadAllText($path)
        $out += "Checking syntax of: $file"
        
        # Try parsing as XML (this will fail for complex HTML but handles basic structural integrity)
        try {
            $xml = [xml]$content
            $out += "  XML Parse Success! (No major tag unbalances)"
        } catch {
            $out += "  XML Parse Note (standard for HTML5): $($_.Exception.Message)"
        }
        
        # Check matching count of <div and </div
        $divOpen = ([regex]::Matches($content, "<div")).Count
        $divClose = ([regex]::Matches($content, "</div")).Count
        $out += "  Div tags: <div count = $divOpen, </div count = $divClose"
        if ($divOpen -ne $divClose) {
            $out += "  WARNING: Mismatched div tags! (Difference: $($divOpen - $divClose))"
        } else {
            $out += "  Div tags are balanced!"
        }
        $out += "--------------------------------------"
    }
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\verify_html_out.txt" -Encoding utf8
Write-Host "Done"

$path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html"
$out = @()
if (Test-Path $path) {
    $content = [System.IO.File]::ReadAllText($path)
    $matches = [regex]::Matches($content, 'id="pdPaper"|class="paper-logo-cell"')
    $out += "Total matches: $($matches.Count)"
    foreach ($m in $matches) {
        $out += "Match: $($m.Value) at index $($m.Index)"
        $out += "  Context: $($content.Substring($m.Index, 300))"
        $out += "----------------------------------"
    }
} else {
    $out += "Index.html not found!"
}
$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\check_index_pd_out.txt" -Encoding utf8
Write-Host "Done"

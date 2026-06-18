$path = 'C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html'
$html = [System.IO.File]::ReadAllText($path)
$html = $html -replace "`r`n", "`n"

$matches = [regex]::Matches($html, '(?s)<section id="view-([^"]+)"[^>]*>(.*?)</section>')
foreach ($m in $matches) {
    $viewId = $m.Groups[1].Value
    $subHtml = $m.Groups[2].Value
    
    $openDivs = [regex]::Matches($subHtml, '<div\b').Count
    $closeDivs = [regex]::Matches($subHtml, '</div>').Count
    
    if ($openDivs -ne $closeDivs) {
        Write-Host "View '$viewId' is UNBALANCED in Index.html: $openDivs opening vs $closeDivs closing divs"
    } else {
        Write-Host "View '$viewId' is balanced in Index.html ($openDivs divs)"
    }
}

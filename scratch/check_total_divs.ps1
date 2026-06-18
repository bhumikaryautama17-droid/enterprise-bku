$path = 'C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html'
$content = [System.IO.File]::ReadAllText($path)
$opens = [regex]::Matches($content, '<div\b').Count
$closes = [regex]::Matches($content, '</div>').Count
Write-Host "index_local_preview.html Total Divs: $opens open vs $closes close"

$path2 = 'C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Index.html'
$content2 = [System.IO.File]::ReadAllText($path2)
$opens2 = [regex]::Matches($content2, '<div\b').Count
$closes2 = [regex]::Matches($content2, '</div>').Count
Write-Host "Index.html Total Divs: $opens2 open vs $closes2 close"

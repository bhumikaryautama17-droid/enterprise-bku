$content = Get-Content Code.js -Raw
$content = $content -replace "return d.toLocaleDateString\('id-ID', \{ day: '2-digit', month: 'short', year: 'numeric' \}\);", "return Utilities.formatDate(d, 'GMT+8', 'dd MMM yyyy');"
$content | Out-File Code.js -Encoding UTF8
Write-Host "Fixed formatDate"

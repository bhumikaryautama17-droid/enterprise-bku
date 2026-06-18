$content = Get-Content "index_local_preview.html" -Raw
if ($content -match "(?s)(function buildPaperHTML\(doc\) \{.*?\n\})") {
    $matches[1] | Out-File "scratch\buildPaperHTML.txt" -Encoding UTF8
    Write-Host "Extracted buildPaperHTML!"
} else {
    Write-Host "Not found."
}

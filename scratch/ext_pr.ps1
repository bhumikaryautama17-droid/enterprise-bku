$content = Get-Content scratch\buildPaperHTML.txt -Raw
if ($content -match "base64,([a-zA-Z0-9+/=]+)") {
    $matches[1] | Out-File scratch\pr_base64.txt -Encoding UTF8
    Write-Host "Extracted PR logo!"
}

$line = (Get-Content index_local_preview.html)[588]
if ($line -match "base64,([a-zA-Z0-9+/=]+)") {
    $matches[1] | Out-File scratch\pd_base64.txt -Encoding UTF8
    Write-Host "Extracted PD base64!"
}

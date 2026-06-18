$content = Get-Content index_local_preview.html -Raw
if ($content -match "(doc\.type === 'PD' \? 'data:image/jpeg;base64,[a-zA-Z0-9+/=]+' : 'data:image/png;base64,[a-zA-Z0-9+/=]+')") {
    $matches[1] | Out-File scratch\logo_logic.txt -Encoding UTF8
    Write-Host "Found logo logic!"
}

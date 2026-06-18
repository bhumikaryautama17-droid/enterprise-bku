$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
for ($i = 1350; $i -le 1380; $i++) {
    $line = $lines[$i] -replace 'data:image/png;base64,[a-zA-Z0-9+/=]+', '[PNG_BASE64]'
    $line = $line -replace 'data:image/jpeg;base64,[a-zA-Z0-9+/=]+', '[JPEG_BASE64]'
    Write-Host "$i`: $line"
}

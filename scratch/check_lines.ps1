$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($line -match "data:image/jpeg;base64,") {
        Write-Host "Found on line $($i + 1)"
        Write-Host $line.Substring(0, [math]::Min(100, $line.Length))
        Write-Host "..."
        Write-Host $line.Substring([math]::Max(0, $line.Length - 100))
    }
}

$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
for ($i = 3450; $i -le 3573; $i++) {
    if ($i -ge $lines.Length) { break }
    $line = $lines[$i]
    if ($line -match "return") {
        Write-Host "$i`: $line"
    } elseif ($line -match "}") {
        Write-Host "$i`: $line"
    }
}

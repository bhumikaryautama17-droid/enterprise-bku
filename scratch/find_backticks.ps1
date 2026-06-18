$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
$btCount = 0
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    for ($j = 0; $j -lt $line.Length; $j++) {
        if ($line[$j] -eq '`') {
            $btCount++
            Write-Host "Backtick #$btCount found at line $($i + 1)"
        }
    }
}

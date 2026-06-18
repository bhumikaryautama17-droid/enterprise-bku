$lines = Get-Content 'Index.html'
$level = 0
for ($i = 1031; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $opens = [regex]::Matches($line, '<div\b').Count
    $closes = [regex]::Matches($line, '</div>').Count
    $level += ($opens - $closes)
    if ($opens -gt 0 -or $closes -gt 0) {
        Write-Host "Line $($i+1) (Lvl $level): $opens open, $closes close | $($line.Trim())"
    }
}
Write-Host "Final level after 1031: $level"

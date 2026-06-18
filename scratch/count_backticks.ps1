$codeJs = Get-Content -Path "Code.js" -Raw
$backticks = 0
for ($i = 0; $i -lt $codeJs.Length; $i++) {
    if ($codeJs[$i] -eq '`') {
        $backticks++
    }
}
Write-Host "Total backticks: $backticks"

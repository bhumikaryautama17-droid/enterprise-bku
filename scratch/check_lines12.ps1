$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
for ($i = 3230; $i -le 3245; $i++) {
    Write-Host "$i`: $($lines[$i])"
}

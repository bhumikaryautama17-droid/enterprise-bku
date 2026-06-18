$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
for ($i = 3260; $i -le 3280; $i++) {
    $len = [math]::Min(150, $lines[$i].Length)
    Write-Host "$i`: $($lines[$i].Substring(0, $len))"
}

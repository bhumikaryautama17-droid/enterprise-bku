$jsonText = Get-Content "scratch\generatePDF_raw.txt" -Raw
$obj = ConvertFrom-Json "{ `"code`": $jsonText }"
$obj.code | Out-File scratch\generatePDF_real.txt -Encoding UTF8
Write-Host "Done!"

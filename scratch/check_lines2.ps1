$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"
Write-Host "Line 3271:"
Write-Host $lines[3270].Substring(0, [math]::Min(150, $lines[3270].Length))
Write-Host "Line 3272:"
Write-Host $lines[3271].Substring(0, [math]::Min(150, $lines[3271].Length))
Write-Host "Line 3273:"
Write-Host $lines[3272].Substring(0, [math]::Min(150, $lines[3272].Length))

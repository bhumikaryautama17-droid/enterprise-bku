$lines = Get-Content Code.js
for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match "^function generatePDF") {
        Write-Host "Start: $i"
    }
    if ($lines[$i] -match "^// Terbilang helper") {
        Write-Host "End: $i"
    }
}

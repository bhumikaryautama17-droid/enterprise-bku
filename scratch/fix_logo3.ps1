$code = Get-Content Code.js -Raw
$pngBase64 = (Get-Content scratch\pr_base64.txt -Raw).Trim()
$jpegBase64 = (Get-Content scratch\pd_base64.txt -Raw).Trim()

$startString = '<img src="data:image/png;base64,'
$endString = 'PT. BHUMI KARYA UTAMA</div>'

$startIndex = $code.IndexOf($startString)
if ($startIndex -ge 0) {
    $endIndex = $code.IndexOf($endString, $startIndex)
    if ($endIndex -ge 0) {
        $endIndex += $endString.Length
        
        $part1 = $code.Substring(0, $startIndex)
        $part2 = $code.Substring($endIndex)
        
        $replacement = '<img src="'' + (doc.type === ''PD'' ? ''data:image/jpeg;base64,' + $jpegBase64 + ''' : ''data:image/png;base64,' + $pngBase64 + ''') + ''" style="max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\r\n              <div style="font-size:8.5px;color:#444;text-align:center;line-height:1.4;font-weight:bold;">'' + (doc.type === ''PD'' ? ''PT. BARA INDAH SINERGI'' : ''PT. BHUMI KARYA UTAMA'') + ''</div>'
        
        $newCode = $part1 + $replacement + $part2
        $newCode | Out-File Code.js -Encoding UTF8
        Write-Host "Replaced successfully using IndexOf!"
    } else {
        Write-Host "End string not found"
    }
} else {
    Write-Host "Start string not found"
}

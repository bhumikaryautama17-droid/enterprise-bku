$code = Get-Content Code.js -Raw
$pngBase64 = (Get-Content scratch\pr_base64.txt -Raw).Trim()
$jpegBase64 = (Get-Content scratch\pd_base64.txt -Raw).Trim()

$pattern = '<img src="data:image/png;base64,' + $pngBase64 + '" style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />' + "`r`n" + '              <div style="font-size:8px; color:#111; font-weight:bold; line-height:1.2;">PT. BHUMI KARYA UTAMA</div>'

$replacement = '<img src="'' + (doc.type === ''PD'' ? ''data:image/jpeg;base64,' + $jpegBase64 + ''' : ''data:image/png;base64,' + $pngBase64 + ''') + ''" style="max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />' + "`r`n" + '              <div style="font-size:8.5px;color:#444;text-align:center;line-height:1.4;font-weight:bold;">'' + (doc.type === ''PD'' ? ''PT. BARA INDAH SINERGI'' : ''PT. BHUMI KARYA UTAMA'') + ''</div>'

if ($code.Contains($pattern)) {
    $code = $code.Replace($pattern, $replacement)
    $code | Out-File Code.js -Encoding UTF8
    Write-Host "Replaced logo successfully!"
} else {
    Write-Host "Pattern not found. Trying with \n..."
    $pattern2 = '<img src="data:image/png;base64,' + $pngBase64 + '" style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />' + "`n" + '              <div style="font-size:8px; color:#111; font-weight:bold; line-height:1.2;">PT. BHUMI KARYA UTAMA</div>'
    if ($code.Contains($pattern2)) {
        $code = $code.Replace($pattern2, $replacement)
        $code | Out-File Code.js -Encoding UTF8
        Write-Host "Replaced logo successfully with \n!"
    } else {
        Write-Host "Still not found!"
    }
}

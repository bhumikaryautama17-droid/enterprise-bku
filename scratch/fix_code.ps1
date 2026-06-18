$indexHtml = Get-Content -Path "index_local_preview.html" -Raw
if ($indexHtml -match '<img src="(data:image/png;base64,[^"]+)"[^>]*>\s*<div[^>]*>PT\. BHUMI KARYA UTAMA</div>') {
    $pngBase64 = $matches[1]
    $codeJs = Get-Content -Path "Code.js" -Raw
    
    $startIndex = $codeJs.IndexOf('<td style="width: 25%; text-align: center;">'' +')
    $endIndex = $codeJs.IndexOf('<td style="width: 45%; text-align: center;">'' +')
    
    if ($startIndex -ge 0 -and $endIndex -ge 0) {
        $snippet = $codeJs.Substring($startIndex, $endIndex - $startIndex)
        if ($snippet -match '(data:image/jpeg;base64,[a-zA-Z0-9+/=]+)') {
            $jpegBase64 = $matches[1]
            
            $replacement = "<td style=`"width: 25%; text-align: center;`">' +`r`n        '<img src=`"' + (data.type === 'PD' ? '$jpegBase64' : '$pngBase64') + '`" style=`"max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;`" />' +`r`n        '<div style=`"font-size:8.5px;color:#444;text-align:center;line-height:1.4;font-weight:bold;`">' + (data.type === 'PD' ? 'PT. BARA INDAH SINERGI' : 'PT. BHUMI KARYA UTAMA') + '</div>' +`r`n        '</td>' +`r`n        '"
            
            $codeJs = $codeJs.Substring(0, $startIndex) + $replacement + $codeJs.Substring($endIndex)
            Set-Content -Path "Code.js" -Value $codeJs -Encoding UTF8 -NoNewline
            Write-Host "Code.js fixed successfully."
        } else {
            Write-Host "JPEG base64 not found in snippet."
        }
    } else {
        Write-Host "Markers not found."
    }
} else {
    Write-Host "PNG base64 not found."
}

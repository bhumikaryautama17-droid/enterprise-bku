$indexHtml = Get-Content -Path "index_local_preview.html" -Raw
$startStr = '<img src="data:image/png;base64,'
$endStr = '" style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />'
$startIndex = $indexHtml.IndexOf($startStr)
if ($startIndex -ge 0) {
    $startIndex = $startIndex + $startStr.Length
    $endIndex = $indexHtml.IndexOf($endStr, $startIndex)
    if ($endIndex -ge 0) {
        $pngBase64 = "data:image/png;base64," + $indexHtml.Substring($startIndex, $endIndex - $startIndex)
        
        $codeJs = Get-Content -Path "Code.js" -Raw
        $codeStart = '<td style="width: 25%; text-align: center;">'' +'
        $codeEnd = '<td style="width: 45%; text-align: center;">'' +'
        
        $cStart = $codeJs.IndexOf($codeStart)
        $cEnd = $codeJs.IndexOf($codeEnd, $cStart)
        
        if ($cStart -ge 0 -and $cEnd -ge 0) {
            $snippet = $codeJs.Substring($cStart, $cEnd - $cStart)
            $jpegStartStr = 'data:image/jpeg;base64,'
            $jStart = $snippet.IndexOf($jpegStartStr)
            if ($jStart -ge 0) {
                $jEnd = $snippet.IndexOf("'", $jStart)
                $jpegBase64 = $snippet.Substring($jStart, $jEnd - $jStart)
                
                $replacement = "<td style=`"width: 25%; text-align: center;`">' +`r`n        '<img src=`"' + (data.type === 'PD' ? '$jpegBase64' : '$pngBase64') + '`" style=`"max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;`" />' +`r`n        '<div style=`"font-size:8.5px;color:#444;text-align:center;line-height:1.4;font-weight:bold;`">' + (data.type === 'PD' ? 'PT. BARA INDAH SINERGI' : 'PT. BHUMI KARYA UTAMA') + '</div>' +`r`n        '</td>' +`r`n        '"
                
                $codeJs = $codeJs.Substring(0, $cStart) + $replacement + $codeJs.Substring($cEnd)
                Set-Content -Path "Code.js" -Value $codeJs -Encoding UTF8 -NoNewline
                Write-Host "Code.js fixed successfully."
            } else { Write-Host "JPEG base64 not found" }
        } else { Write-Host "Markers not found in Code.js" }
    } else { Write-Host "End string not found in index_local_preview.html" }
} else { Write-Host "Start string not found in index_local_preview.html" }

$codeJs = Get-Content -Path "Code.js" -Raw
$lines = $codeJs -split "`n"

$pngBase64 = ""
$jpegBase64 = ""

if ($codeJs -match "data:image/png;base64,([A-Za-z0-9+/=]+)") {
    $pngBase64 = "data:image/png;base64," + $matches[1]
}
if ($codeJs -match "data:image/jpeg;base64,([A-Za-z0-9+/=]+)") {
    $jpegBase64 = "data:image/jpeg;base64," + $matches[1]
}

$startIndex = -1
$endIndex = -1

for ($i = 3255; $i -lt 3280; $i++) {
    if ($lines[$i] -match "</style>") {
        $startIndex = $i
        break
    }
}

for ($i = $startIndex; $i -lt 3280; $i++) {
    if ($lines[$i] -match "width: 45%; text-align: center;") {
        $endIndex = $i
        break
    }
}

if ($startIndex -ge 0 -and $endIndex -gt $startIndex) {
    $replacement = "      </style>`` +`r`n"
    $replacement += "      '<div style=`"font-family:Arial,sans-serif; background:#fff; color:#111; padding:10px; font-size:9px; border:1.5px solid #111; box-sizing:border-box; max-width:1080px; margin:0 auto;`">' +`r`n"
    $replacement += "        '<!-- Header -->' +`r`n"
    $replacement += "        '<table style=`"width:100%; border-collapse:collapse; border:1.5px solid #111; margin-bottom:8px;`">' +`r`n"
    $replacement += "          '<tr>' +`r`n"
    $replacement += "            '<td style=`"width:25%; text-align:center; border:1px solid #111; padding:6px; vertical-align:middle;`">' +`r`n"
    $replacement += "              '<img src=`"' + (data.type === 'PD' ? '$jpegBase64' : '$pngBase64') + '`" style=`"max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;`" />' +`r`n"
    $replacement += "              '<div style=`"font-size:8.5px;color:#444;text-align:center;line-height:1.4;font-weight:bold;`">' + (data.type === 'PD' ? 'PT. BARA INDAH SINERGI' : 'PT. BHUMI KARYA UTAMA') + '</div>' +`r`n"
    $replacement += "            '</td>' +"

    $newLines = @()
    for ($i = 0; $i -lt $startIndex; $i++) {
        $newLines += $lines[$i]
    }
    $newLines += $replacement
    for ($i = $endIndex; $i -lt $lines.Length; $i++) {
        $newLines += $lines[$i]
    }
    
    $newCodeJs = $newLines -join "`n"
    Set-Content -Path "Code.js" -Value $newCodeJs -Encoding UTF8 -NoNewline
    Write-Host "Fixed syntax error for PD HTML generation successfully."
} else {
    Write-Host "Could not find start or end index. Start: $startIndex, End: $endIndex"
}

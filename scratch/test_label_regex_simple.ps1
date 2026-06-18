$previewPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$jsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\JavaScript.html"
$codeJsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Code.js"

$out = @()

# Test 1: index_local_preview.html screen preview logo (this has real newlines)
if (Test-Path $previewPath) {
    $content = [System.IO.File]::ReadAllText($previewPath)
    $pattern1 = 'style="max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\s*<div style="font-size:8\.5px;color:#444;text-align:center;line-height:1\.4;font-weight:bold;">PT\. BARA INDAH SINERGI</div>'
    $matches1 = [regex]::Matches($content, $pattern1)
    $out += "Test 1 (index_local_preview.html screen preview): $($matches1.Count) matches"
}

# Test 2: index_local_preview.html print preview logo (this has literal \r\n text)
if (Test-Path $previewPath) {
    $content = [System.IO.File]::ReadAllText($previewPath)
    $pattern2 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\\r\\n\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BHUMI KARYA UTAMA</div>'
    $matches2 = [regex]::Matches($content, $pattern2)
    $out += "Test 2 (index_local_preview.html print preview): $($matches2.Count) matches"
}

# Test 3: JavaScript.html print preview logo (this has real or literal \r\n?)
if (Test-Path $jsPath) {
    $content = [System.IO.File]::ReadAllText($jsPath)
    # Let's try both literal \r\n and whitespace
    $pattern3 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />(\\r\\n|\s)*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BARA INDAH SINERGI</div>'
    $matches3 = [regex]::Matches($content, $pattern3)
    $out += "Test 3 (JavaScript.html print preview): $($matches3.Count) matches"
}

# Test 4: Code.js print PDF logo
if (Test-Path $codeJsPath) {
    $content = [System.IO.File]::ReadAllText($codeJsPath)
    $pattern4 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\\r\\n\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BHUMI KARYA UTAMA</div>'
    $matches4 = [regex]::Matches($content, $pattern4)
    $out += "Test 4 (Code.js print PDF): $($matches4.Count) matches"
}

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\label_regex_simple_out.txt" -Encoding utf8
Write-Host "Done"

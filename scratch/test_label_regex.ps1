$base64Path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\bara_indah_logo_b64.txt"
$newLogoBase64 = (Get-Content $base64Path -Raw).Trim() -replace "\r?\n", ""

$previewPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$jsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\JavaScript.html"
$codeJsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Code.js"

$out = @()

# Test 1: index_local_preview.html screen preview logo
if (Test-Path $previewPath) {
    $content = [System.IO.File]::ReadAllText($previewPath)
    $pattern1 = '(<img src="data:image/jpeg;base64,\/9j\/[A-Za-z0-9+/=\s\r\n]{120000,160000}" style="max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />)\s*<div style="font-size:8\.5px;color:#444;text-align:center;line-height:1\.4;font-weight:bold;">PT\. BARA INDAH SINERGI</div>'
    $matches1 = [regex]::Matches($content, $pattern1)
    $out += "Test 1 (index_local_preview.html screen preview): $($matches1.Count) matches"
    foreach ($m in $matches1) {
        $out += "  Match: $($m.Value.Substring(0, 100)) ... $($m.Value.Substring($m.Value.Length - 100))"
    }
}

# Test 2: index_local_preview.html print preview logo
if (Test-Path $previewPath) {
    $content = [System.IO.File]::ReadAllText($previewPath)
    $pattern2 = '(<img src="data:image/jpeg;base64,\/9j\/[A-Za-z0-9+/=\s\r\n]{120000,160000}" style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />)\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BHUMI KARYA UTAMA</div>'
    $matches2 = [regex]::Matches($content, $pattern2)
    $out += "Test 2 (index_local_preview.html print preview): $($matches2.Count) matches"
    foreach ($m in $matches2) {
        $out += "  Match: $($m.Value.Substring(0, 100)) ... $($m.Value.Substring($m.Value.Length - 100))"
    }
}

# Test 3: JavaScript.html print preview logo
if (Test-Path $jsPath) {
    $content = [System.IO.File]::ReadAllText($jsPath)
    $pattern3 = '(<img src="data:image/jpeg;base64,\/9j\/[A-Za-z0-9+/=\s\r\n]{120000,160000}" style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />)\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BARA INDAH SINERGI</div>'
    $matches3 = [regex]::Matches($content, $pattern3)
    $out += "Test 3 (JavaScript.html print preview): $($matches3.Count) matches"
    foreach ($m in $matches3) {
        $out += "  Match: $($m.Value.Substring(0, 100)) ... $($m.Value.Substring($m.Value.Length - 100))"
    }
}

# Test 4: Code.js print PDF logo
if (Test-Path $codeJsPath) {
    $content = [System.IO.File]::ReadAllText($codeJsPath)
    $pattern4 = '(<img src="data:image/jpeg;base64,\/9j\/[A-Za-z0-9+/=\s\r\n]{120000,160000}" style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />)\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BHUMI KARYA UTAMA</div>'
    $matches4 = [regex]::Matches($content, $pattern4)
    $out += "Test 4 (Code.js print PDF): $($matches4.Count) matches"
    foreach ($m in $matches4) {
        $out += "  Match: $($m.Value.Substring(0, 100)) ... $($m.Value.Substring($m.Value.Length - 100))"
    }
}

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\label_regex_out.txt" -Encoding utf8
Write-Host "Done"

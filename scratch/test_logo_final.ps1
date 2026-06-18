$previewPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$jsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\JavaScript.html"
$codeJsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Code.js"

$out = @()

# Verify index_local_preview.html screen preview logo
if (Test-Path $previewPath) {
    $content = [System.IO.File]::ReadAllText($previewPath)
    $pattern1 = 'style="max-height:85px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $matches1 = [regex]::Matches($content, $pattern1)
    $out += "Test 1 (index_local_preview.html screen preview logo updated): $($matches1.Count) matches"
}

# Verify index_local_preview.html print preview logo
if (Test-Path $previewPath) {
    $content = [System.IO.File]::ReadAllText($previewPath)
    # The replaced print preview logo is style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />
    # Wait, does the PR logo also have max-height:100px or other?
    # Let's see: the pattern is max-height:95px
    $pattern2 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $matches2 = [regex]::Matches($content, $pattern2)
    $out += "Test 2 (index_local_preview.html print preview logo updated): $($matches2.Count) matches"
}

# Verify JavaScript.html print preview logo
if (Test-Path $jsPath) {
    $content = [System.IO.File]::ReadAllText($jsPath)
    $pattern3 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $matches3 = [regex]::Matches($content, $pattern3)
    $out += "Test 3 (JavaScript.html print preview logo updated): $($matches3.Count) matches"
}

# Verify Code.js print PDF logo
if (Test-Path $codeJsPath) {
    $content = [System.IO.File]::ReadAllText($codeJsPath)
    $pattern4 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $matches4 = [regex]::Matches($content, $pattern4)
    $out += "Test 4 (Code.js print PDF logo updated): $($matches4.Count) matches"
}

$out | Out-File -FilePath "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\scratch\logo_final_out.txt" -Encoding utf8
Write-Host "Done"

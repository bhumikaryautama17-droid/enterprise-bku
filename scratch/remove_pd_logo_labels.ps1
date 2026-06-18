$previewPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$jsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\JavaScript.html"
$codeJsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Code.js"

# Backup files (if not already backed up)
function Backup-File($filePath) {
    $backupPath = "$filePath.bak2"
    Copy-Item -Path $filePath -Destination $backupPath -Force
    Write-Host "Backed up $filePath to $backupPath"
}

# Update index_local_preview.html
if (Test-Path $previewPath) {
    Backup-File $previewPath
    $content = [System.IO.File]::ReadAllText($previewPath)
    
    # 1. Screen preview logo
    $pattern1 = 'style="max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\s*<div style="font-size:8\.5px;color:#444;text-align:center;line-height:1\.4;font-weight:bold;">PT\. BARA INDAH SINERGI</div>'
    $replacement1 = 'style="max-height:85px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $content = [regex]::Replace($content, $pattern1, $replacement1)
    
    # 2. Print preview logo
    $pattern2 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\\r\\n\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BHUMI KARYA UTAMA</div>'
    $replacement2 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $content = [regex]::Replace($content, $pattern2, $replacement2)
    
    [System.IO.File]::WriteAllText($previewPath, $content)
    Write-Host "Updated $previewPath"
}

# Update JavaScript.html
if (Test-Path $jsPath) {
    Backup-File $jsPath
    $content = [System.IO.File]::ReadAllText($jsPath)
    
    # 3. Print preview logo
    $pattern3 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />(\\r\\n|\s)*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BARA INDAH SINERGI</div>'
    $replacement3 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $content = [regex]::Replace($content, $pattern3, $replacement3)
    
    [System.IO.File]::WriteAllText($jsPath, $content)
    Write-Host "Updated $jsPath"
}

# Update Code.js
if (Test-Path $codeJsPath) {
    Backup-File $codeJsPath
    $content = [System.IO.File]::ReadAllText($codeJsPath)
    
    # 4. Print PDF logo
    $pattern4 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />\\r\\n\s*<div style="font-size:8px; color:#111; font-weight:bold; line-height:1\.2;">PT\. BHUMI KARYA UTAMA</div>'
    $replacement4 = 'style="max-height:95px; max-width:100%; object-fit:contain; display:block; margin:0 auto;" />'
    $content = [regex]::Replace($content, $pattern4, $replacement4)
    
    [System.IO.File]::WriteAllText($codeJsPath, $content)
    Write-Host "Updated $codeJsPath"
}

Write-Host "Done replacements"

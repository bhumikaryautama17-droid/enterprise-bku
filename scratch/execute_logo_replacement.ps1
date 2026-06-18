# Define paths
$base64Path = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\bara_indah_logo_b64.txt"
$previewPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\index_local_preview.html"
$codeJsPath = "C:\Users\LENOVO\.gemini\antigravity\scratch\apps-script-workflow-approval\Code.js"

# Read base64 logo
if (!(Test-Path $base64Path)) {
    Write-Error "Base64 logo file not found!"
    exit 1
}
$newLogoBase64 = (Get-Content $base64Path -Raw).Trim() -replace "\r?\n", ""

# Backup function
function Backup-File($filePath) {
    if (Test-Path $filePath) {
        $backupPath = "$filePath.bak"
        Copy-Item -Path $filePath -Destination $backupPath -Force
        Write-Host "Backed up $filePath to $backupPath"
    }
}

# Update function
function Update-Logo($filePath) {
    if (Test-Path $filePath) {
        Backup-File $filePath
        $content = [System.IO.File]::ReadAllText($filePath)
        
        # Pattern to find PD landscape print layout logo (which is Bhumi Karya logo of length ~12890)
        $pattern = '(<td style="width:25%; text-align:center; border:1px solid #111; padding:6px; vertical-align:middle;">\s*<img src=")(data:image/png;base64,iVBORw0KGgoAAA[A-Za-z0-9+/=\s\r\n]{12000,13000})(" style="max-height:95px;)'
        
        $matches = [regex]::Matches($content, $pattern)
        if ($matches.Count -eq 1) {
            # Perform regex replacement
            $replacement = '${1}' + "data:image/jpeg;base64,$newLogoBase64" + '${3}'
            $newContent = [regex]::Replace($content, $pattern, $replacement)
            [System.IO.File]::WriteAllText($filePath, $newContent)
            Write-Host "Successfully replaced logo in $filePath"
        } else {
            Write-Warning "Expected exactly 1 match in $filePath, but found $($matches.Count). No changes made."
        }
    } else {
        Write-Warning "File not found: $filePath"
    }
}

# Perform updates
Update-Logo $previewPath
Update-Logo $codeJsPath
Write-Host "Execution completed"

# build_cpanel.ps1
# This script copies the index_cpanel.html as the main entrypoint
# and bundles it with the SQLite backend files into apps-script-workflow-approval-cpanel.zip.

$currentDir = $PSScriptRoot
if (-not $currentDir) { $currentDir = "." }

$distDir = Join-Path $currentDir "dist_cpanel"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

Write-Host "Copying index_cpanel.html to dist_cpanel/index.html..." -ForegroundColor Cyan
$sourceHtml = Join-Path $currentDir "index_cpanel.html"
$destHtml = Join-Path $distDir "index.html"
if (Test-Path $sourceHtml) {
    Copy-Item -Path $sourceHtml -Destination $destHtml -Force
    Write-Host "Production HTML copied successfully" -ForegroundColor Green
} else {
    Write-Error "Source index_cpanel.html not found!"
    Exit 1
}

# Copy api.php, schema.sql, diagnose.php, test_mail.php and .htaccess to dist_cpanel
Write-Host "Copying backend files to dist_cpanel..." -ForegroundColor Cyan
Copy-Item -Path (Join-Path $currentDir "api.php") -Destination (Join-Path $distDir "api.php") -Force
Copy-Item -Path (Join-Path $currentDir "schema.sql") -Destination (Join-Path $distDir "schema.sql") -Force
Copy-Item -Path (Join-Path $currentDir "diagnose.php") -Destination (Join-Path $distDir "diagnose.php") -Force
Copy-Item -Path (Join-Path $currentDir "test_mail.php") -Destination (Join-Path $distDir "test_mail.php") -Force
$htaccessPath = Join-Path $currentDir ".htaccess"
if (Test-Path $htaccessPath) {
    Copy-Item -Path $htaccessPath -Destination (Join-Path $distDir ".htaccess") -Force
}
$bgImgPath = Join-Path $currentDir "bku_mining_sunset.png"
if (Test-Path $bgImgPath) {
    Copy-Item -Path $bgImgPath -Destination (Join-Path $distDir "bku_mining_sunset.png") -Force
}

# Clean up obsolete config.php if exists
$obsoleteConfig = Join-Path $distDir "config.php"
if (Test-Path $obsoleteConfig) {
    Remove-Item -Path $obsoleteConfig -Force
    Write-Host "Removed obsolete config.php" -ForegroundColor Yellow
}

# Zip the bundle
Write-Host "Packaging cPanel SQLite distribution ZIP..." -ForegroundColor Cyan
$zipPath = Join-Path (Split-Path $currentDir -Parent) "apps-script-workflow-approval-cpanel.zip"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

# Use Compress-Archive to package all files in dist_cpanel
Compress-Archive -Path (Join-Path $distDir "*") -DestinationPath $zipPath -Force
Write-Host "Distribution ZIP packaged successfully at: $zipPath" -ForegroundColor Green

Write-Host "Build complete! Please upload the ZIP file to your public_html directory." -ForegroundColor Green

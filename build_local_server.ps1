# build_local_server.ps1
# This script bundles the Index.html, Stylesheet.html, and JavaScript.html
# into a single index.html designed to run on the Local Node.js server.

$currentDir = $PSScriptRoot
if (-not $currentDir) { $currentDir = "." }

$distDir = Join-Path $currentDir "dist_local_server"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

Write-Host "Reading source files..." -ForegroundColor Cyan
$indexPath = Join-Path $currentDir "Index.html"
$stylePath = Join-Path $currentDir "Stylesheet.html"
$scriptPath = Join-Path $currentDir "JavaScript.html"

if (-not (Test-Path $indexPath) -or -not (Test-Path $stylePath) -or -not (Test-Path $scriptPath)) {
    Write-Error "Source files not found!"
    Exit 1
}

$indexContent = Get-Content -Raw -Path $indexPath
$styleContent = Get-Content -Raw -Path $stylePath
$scriptContent = Get-Content -Raw -Path $scriptPath

# Define the Local Server Database Connector and Interceptor JS code (using single quotes)
$localInterceptor = @'
// ============================================================================
// LOCAL SERVER DATABASE CONNECTOR & INTERCEPTOR FOR LAN DEPLOYMENT
// ============================================================================
(function() {
  const isGAS = (typeof google !== 'undefined' && google.script && google.script.run && google.script.sandboxMode);
  if (!isGAS) {
    window.google = {
      script: {
        run: {
          withSuccessHandler: function(successCallback) {
            this.success = successCallback;
            return this;
          },
          withFailureHandler: function(failureCallback) {
            this.failure = failureCallback;
            return this;
          }
        }
      }
    };

    const apiActions = [
      'getDropdownData', 'getDashboardData', 'getApprovalRequests', 'processApproval',
      'getDocumentHistory', 'saveUserSignature', 'createUserRecord', 'editUserRecord',
      'deleteUserRecord', 'saveBudgetLive', 'deleteBudgetLive', 'importBudgetLiveCSV',
      'submitRequest', 'createMasterRecord', 'updateMasterRecord', 'deleteMasterRecord', 'loginUser'
    ];

    apiActions.forEach(action => {
      window.google.script.run[action] = function(...args) {
        const success = this.success;
        const failure = this.failure;
        
        // Perform standard fetch request to the local express API
        fetch('/api/action', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            action: action,
            args: args
          })
        })
        .then(response => response.json())
        .then(res => {
          if (res.success) {
            if (success) success(res.data);
          } else {
            if (failure) failure(res.error);
          }
        })
        .catch(err => {
          if (failure) failure(err.toString());
        });
      };
    });
  }
})();
'@

# Replace standard Apps Script API interceptor at the top with Local Server Interceptor
$interceptorPattern = "(?s)<script>\s*// API FALLBACK INTERCEPTOR FOR VERCEL DEPLOYMENT.*?\n\n/\*\*"
$scriptContent = $scriptContent -replace $interceptorPattern, ("<script>`n" + $localInterceptor + "`n`n/**")

# Combine files
Write-Host "Bundling Stylesheet.html..." -ForegroundColor Cyan
$indexContent = $indexContent.Replace("<?!= include('Stylesheet'); ?>", $styleContent)

Write-Host "Bundling JavaScript.html..." -ForegroundColor Cyan
$indexContent = $indexContent.Replace("<?!= include('JavaScript'); ?>", $scriptContent)

# Write bundled HTML for Local Server
$outHtmlPath = Join-Path $distDir "index.html"
Set-Content -Path $outHtmlPath -Value $indexContent -Encoding utf8
Write-Host "Bundled Local Server file written: $outHtmlPath" -ForegroundColor Green

# Copy Server files
Write-Host "Copying server scripts..." -ForegroundColor Cyan
Copy-Item (Join-Path $currentDir "server.js") -Destination (Join-Path $distDir "server.js") -Force
Copy-Item (Join-Path $currentDir "db") -Destination $distDir -Recurse -Force

# Create package.json for Node.js
$packageJsonPath = Join-Path $distDir "package.json"
$packageJsonContent = @'
{
  "name": "bku-workflow-approval-local",
  "version": "1.0.0",
  "description": "Local server for Bara Indah Sinergi Group Workflow Approval",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.19.2"
  }
}
'@
Set-Content -Path $packageJsonPath -Value $packageJsonContent -Encoding utf8
Write-Host "package.json created: $packageJsonPath" -ForegroundColor Green

# Create start_server.bat
$batPath = Join-Path $distDir "start_server.bat"
$batContent = @'
@echo off
title BARA INDAH SINERGI - Local Office Server
echo Checking for Node.js installation...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js tidak ditemukan di komputer Anda!
    echo Silakan install Node.js terlebih dahulu melalui website: https://nodejs.org/
    echo Setelah install Node.js selesai, silakan buka kembali file bat ini.
    pause
    exit
)

echo Node.js ditemukan.
if not exist node_modules (
    echo Menginstal dependensi server (express, cors)...
    call npm install
)

echo Menjalankan server lokal...
node server.js
pause
'@
Set-Content -Path $batPath -Value $batContent -Encoding utf8
Write-Host "start_server.bat created: $batPath" -ForegroundColor Green

# Create README.md
$readmePath = Join-Path $distDir "README.md"
$readmeContent = @'
# Bara Indah Sinergi Group - Workflow Approval (Local Office Server)

Aplikasi workflow approval ini berjalan sebagai server lokal di jaringan Wi-Fi/LAN kantor Anda tanpa menggunakan Vercel, GitHub, atau Google Apps Script. 

## Struktur Folder
- `index.html`: Halaman utama aplikasi (HTML + CSS + JS).
- `server.js`: Script backend Node.js / Express server.
- `package.json`: Definisi dependensi node.
- `start_server.bat`: File pintasan untuk instalasi otomatis dan memulai server.
- `db/`: Folder database berisi file JSON database.

## Cara Penggunaan (Deployment Kantor)

### 1. Di Komputer Server Kantor
1. Download dan instal **Node.js** di komputer ini dari website resmi: **[nodejs.org](https://nodejs.org/)** (pilih versi LTS).
2. Salin folder ini ke komputer server tersebut.
3. Klik dua kali file **`start_server.bat`**.
4. Bat file akan menginstal modul-modul server secara otomatis dan langsung menyalakan server.
5. Command prompt akan menampilkan alamat IP lokal server tersebut, misalnya:
   - Local Access: `http://localhost:3000`
   - Network Access: `http://192.168.1.50:3000` (alamat inilah yang digunakan oleh komputer staf lain).
6. **Penting**: Biarkan jendela command prompt server tersebut tetap terbuka agar server terus menyala.

### 2. Di Komputer Staf Kantor Lainnya
1. Pastikan komputer staf terhubung ke jaringan Wi-Fi / kabel LAN kantor yang sama dengan Komputer Server.
2. Buka browser (Chrome/Edge/Firefox), ketik alamat IP Network Access server tersebut (misalnya: `http://192.168.1.50:3000`).
3. Web app akan langsung terbuka dan siap digunakan secara instan dengan performa super cepat!
'@
Set-Content -Path $readmePath -Value $readmeContent -Encoding utf8
Write-Host "README.md created: $readmePath" -ForegroundColor Green
Write-Host "Build complete! Folder ready: $distDir" -ForegroundColor Green

# build_github_db.ps1
# This script bundles the Index.html, Stylesheet.html, and JavaScript.html
# into a single index.html designed to run on Vercel/GitHub Pages,
# communicating directly with a GitHub Repository JSON Database.

$currentDir = $PSScriptRoot
if (-not $currentDir) { $currentDir = "." }

$distDir = Join-Path $currentDir "dist_github_db"
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

# Define the GitHub Database Client and Interceptor JS code using literal single-quotes to prevent PS variable expansion
$githubInterceptor = @'
// ============================================================================
// GITHUB JSON DATABASE CONNECTOR & INTERCEPTOR FOR VERCEL DEPLOYMENT
// ============================================================================
const GitHubDB = {
  getCredentials() {
    return {
      owner: localStorage.getItem('github_owner') || '',
      repo: localStorage.getItem('github_repo') || '',
      branch: localStorage.getItem('github_branch') || 'main',
      token: localStorage.getItem('github_token') || ''
    };
  },
  
  isConfigured() {
    const creds = this.getCredentials();
    return creds.owner && creds.repo && creds.token;
  },

  async fetchFile(filename) {
    const creds = this.getCredentials();
    if (!this.isConfigured()) {
      throw new Error("GitHub repository belum dikonfigurasi. Harap atur koneksi di Settings.");
    }
    
    // Fetch directly from API using Raw Accept Header to avoid caching and raw.githubusercontent CORS issues
    const prefixVal = localStorage.getItem('github_db_prefix');
    const prefix = prefixVal !== null ? prefixVal : 'db/';
    const url = `https://api.github.com/repos/${creds.owner}/${creds.repo}/contents/${prefix}${filename}?ref=${creds.branch}&t=${new Date().getTime()}`;
    const response = await fetch(url, {
      headers: {
        'Authorization': `token ${creds.token}`,
        'Accept': 'application/vnd.github.v3.raw'
      }
    });
    
    if (!response.ok) {
      throw new Error(`Gagal membaca file ${filename}: ${response.statusText} (${response.status})`);
    }
    return await response.json();
  },

  async saveFile(filename, data, commitMessage) {
    const creds = this.getCredentials();
    if (!this.isConfigured()) {
      throw new Error("GitHub repository belum dikonfigurasi.");
    }

    const prefixVal = localStorage.getItem('github_db_prefix');
    const prefix = prefixVal !== null ? prefixVal : 'db/';
    const url = `https://api.github.com/repos/${creds.owner}/${creds.repo}/contents/${prefix}${filename}`;
    
    // 1. Get current file SHA to update it
    let sha = '';
    const getRes = await fetch(`${url}?ref=${creds.branch}`, {
      headers: {
        'Authorization': `token ${creds.token}`,
        'Accept': 'application/vnd.github.v3+json'
      }
    });
    if (getRes.ok) {
      const fileData = await getRes.json();
      sha = fileData.sha;
    }
    
    // 2. Commit updated JSON
    const contentBase64 = btoa(unescape(encodeURIComponent(JSON.stringify(data, null, 2))));
    const body = {
      message: commitMessage || `Update ${filename}`,
      content: contentBase64,
      branch: creds.branch
    };
    if (sha) {
      body.sha = sha;
    }

    const putRes = await fetch(url, {
      method: 'PUT',
      headers: {
        'Authorization': `token ${creds.token}`,
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github.v3+json'
      },
      body: JSON.stringify(body)
    });

    if (!putRes.ok) {
      const errData = await putRes.json();
      throw new Error(`Gagal menyimpan file ${filename}: ${errData.message || putRes.statusText}`);
    }
    return await putRes.json();
  }
};

// Intercept google.script.run to run database queries locally on GitHub DB
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
        
        if (!GitHubDB.isConfigured()) {
          if (failure) failure("Koneksi database GitHub belum disetup!");
          return;
        }

        // Execute action asynchronously on the client using GitHubDB
        executeGithubAction(action, args)
          .then(res => {
            if (success) success(res);
          })
          .catch(err => {
            if (failure) failure(err.message || err.toString());
          });
      };
    });
  }
})();

// Action Router mapping backend calls to GitHub DB API
async function executeGithubAction(action, args) {
  switch (action) {
    case 'getDropdownData': {
      const departments = await GitHubDB.fetchFile('m_departments.json');
      const coas = await GitHubDB.fetchFile('m_coas.json');
      return { departments, coas };
    }
    
    case 'getDashboardData': {
      const requests = await GitHubDB.fetchFile('t_requests.json');
      const budget = await GitHubDB.fetchFile('t_budget.json');
      const logs = await GitHubDB.fetchFile('t_activity_log.json');
      return { requests, budget, logs };
    }
    
    case 'getApprovalRequests': {
      const role = args[0];
      const requests = await GitHubDB.fetchFile('t_requests.json');
      const users = await GitHubDB.fetchFile('m_users.json');
      
      const pmUser = users.find(u => u.role === 'Project Manager');
      const isPmLeave = pmUser && pmUser.status === 'Cuti';
      
      return requests.filter(req => {
        if (req.Status !== 'Pending') return false;
        if (role === 'KTT' && isPmLeave && req.CurrentApproverRole === 'Project Manager') {
          return true;
        }
        return req.CurrentApproverRole === role;
      }).map(req => {
        return {
          id: req.ID,
          type: req.Type,
          docNumber: req.DocNumber,
          date: req.Date,
          department: req.Department,
          priority: req.Priority,
          subject: req.Subject,
          requester: req.Requester,
          nominal: parseFloat(req.TotalNominal) || 0,
          signatures: JSON.parse(req.Signatures || '{}'),
          userFor: req.UserFor
        };
      });
    }
    
    case 'processApproval': {
      const [requestId, actionType, role, comment, userName] = args;
      const requests = await GitHubDB.fetchFile('t_requests.json');
      const budget = await GitHubDB.fetchFile('t_budget.json');
      const logs = await GitHubDB.fetchFile('t_activity_log.json');
      const users = await GitHubDB.fetchFile('m_users.json');
      
      const reqIdx = requests.findIndex(r => r.ID === requestId);
      if (reqIdx === -1) throw new Error("Document not found");
      const request = requests[reqIdx];
      
      const pmUser = users.find(u => u.role === 'Project Manager');
      const isPmLeave = pmUser && pmUser.status === 'Cuti';
      let finalRole = role;
      if (role === 'KTT' && isPmLeave && request.CurrentApproverRole === 'Project Manager') {
        finalRole = 'Project Manager';
      }
      
      const signatures = JSON.parse(request.Signatures || '{}');
      const matrix = await GitHubDB.fetchFile('t_approval_matrix.json');
      
      const matched = matrix.filter(m => {
        const typeMatch = m.type === request.Type;
        const deptMatch = m.dept === 'ALL' || m.dept === request.Department;
        const amountMatch = parseFloat(request.TotalNominal) >= m.min && parseFloat(request.TotalNominal) <= m.max;
        return typeMatch && deptMatch && amountMatch;
      });
      const approvalSteps = matched.length ? matched[0].steps : (request.Type === 'PD' ? ['Project Manager','Finance'] : ['Supervisor','Finance','Project Manager']);
      
      function getSigKey(roleVal) {
        var mapping = {
          'Supervisor': 'supervisor',
          'Head Department': 'supervisor',
          'Finance': 'finance',
          'Finance Site': 'finance',
          'Project Manager': 'projectManager',
          'Cost Control': 'costControl',
          'GM/CFO': 'gmCfo'
        };
        return mapping[roleVal] || roleVal.toLowerCase().replace(/[^a-z]/g, '');
      }
      
      var key = getSigKey(finalRole);
      if (request.Type === 'PD') {
        if (finalRole === 'Project Manager' && signatures.deptHeadPm !== undefined) {
          key = 'deptHeadPm';
        } else if (finalRole === 'Finance' && signatures.financeSite !== undefined) {
          key = 'financeSite';
        }
      }
      if (!key) throw new Error('Invalid Approver Role');
      
      if (actionType === 'APPROVE') {
        const user = users.find(u => u.name === userName || u.username === userName);
        const userSig = user ? (user.signature || '') : '';
        
        signatures[key] = {
          name: userName,
          role: finalRole,
          date: new Date().toISOString(),
          status: 'APPROVED',
          signatureText: userSig ? userSig : "[e-Signed: " + userName + " | " + new Date().toISOString().substring(0, 10) + "]"
        };
        
        var currentStepIndex = approvalSteps.indexOf(finalRole);
        var nextApprover = '';
        var nextStatus = 'Pending';
        
        if (currentStepIndex !== -1 && currentStepIndex < approvalSteps.length - 1) {
          nextApprover = approvalSteps[currentStepIndex + 1];
        } else {
          nextStatus = 'Approved';
          nextApprover = 'None';
        }
        
        request.Status = nextStatus;
        request.CurrentApproverRole = nextApprover;
        request.Signatures = JSON.stringify(signatures);
        
        if (nextStatus === 'Approved') {
          const budgetIdx = budget.findIndex(b => b.dept === request.Department);
          if (budgetIdx !== -1) {
            budget[budgetIdx].actual = (budget[budgetIdx].actual || 0) + (parseFloat(request.TotalNominal) || 0);
            budget[budgetIdx].remaining = budget[budgetIdx].annual - budget[budgetIdx].actual;
          }
        }
        
        logs.unshift({
          id: 'LOG-' + new Date().getTime(),
          timestamp: new Date().toISOString(),
          user: userName,
          action: "Approved at " + finalRole,
          module: "Approval",
          document: request.DocNumber,
          ip: '192.168.10.' + Math.floor(Math.random()*200+10)
        });
        
        await GitHubDB.saveFile('t_requests.json', requests, `Approve request ${request.DocNumber} by ${userName}`);
        await GitHubDB.saveFile('t_budget.json', budget, `Consume budget for request ${request.DocNumber}`);
        await GitHubDB.saveFile('t_activity_log.json', logs, `Log approval activity for ${request.DocNumber}`);
        
        return { success: true, status: nextStatus };
        
      } else if (actionType === 'REJECT') {
        signatures[key] = {
          name: userName,
          role: finalRole,
          date: new Date().toISOString(),
          status: 'REJECTED',
          signatureText: "REJECTED"
        };
        
        request.Status = 'Rejected';
        request.CurrentApproverRole = 'None';
        request.Signatures = JSON.stringify(signatures);
        
        logs.unshift({
          id: 'LOG-' + new Date().getTime(),
          timestamp: new Date().toISOString(),
          user: userName,
          action: "Rejected at " + finalRole + " - " + comment,
          module: "Approval",
          document: request.DocNumber,
          ip: '192.168.10.' + Math.floor(Math.random()*200+10)
        });
        
        await GitHubDB.saveFile('t_requests.json', requests, `Reject request ${request.DocNumber} by ${userName}`);
        await GitHubDB.saveFile('t_activity_log.json', logs, `Log rejection activity for ${request.DocNumber}`);
        
        return { success: true, status: 'Rejected' };
      }
      break;
    }
    
    case 'getDocumentHistory': {
      const requests = await GitHubDB.fetchFile('t_requests.json');
      return requests.map(req => {
        return {
          id: req.ID,
          type: req.Type,
          docNumber: req.DocNumber,
          date: req.Date,
          department: req.Department,
          priority: req.Priority,
          subject: req.Subject,
          requester: req.Requester,
          nominal: parseFloat(req.TotalNominal) || 0,
          signatures: JSON.parse(req.Signatures || '{}'),
          userFor: req.UserFor,
          status: req.Status,
          currentApprover: req.CurrentApproverRole
        };
      });
    }
    
    case 'saveUserSignature': {
      const [username, sigDataUrl] = args;
      const users = await GitHubDB.fetchFile('m_users.json');
      const idx = users.findIndex(u => u.username === username);
      if (idx === -1) throw new Error("User not found");
      users[idx].signature = sigDataUrl;
      await GitHubDB.saveFile('m_users.json', users, `Update signature for ${username}`);
      return { success: true };
    }
    
    case 'createUserRecord': {
      const payload = args[0];
      const users = await GitHubDB.fetchFile('m_users.json');
      const count = users.length + 1;
      const existingIds = users.map(row => (row.id || row.ID || '').toString());
      let idValue = 'USR-' + count;
      while (existingIds.indexOf(idValue) !== -1) {
        idValue = 'USR-' + (parseInt(idValue.split('-')[1]) + 1);
      }
      payload.id = idValue;
      payload.ID = idValue;
      payload.signature = '';
      users.push(payload);
      await GitHubDB.saveFile('m_users.json', users, `Create user ${payload.username}`);
      return { success: true, record: payload };
    }
    
    case 'editUserRecord': {
      const [id, payload] = args;
      const users = await GitHubDB.fetchFile('m_users.json');
      const idx = users.findIndex(u => (u.id === id || u.ID === id));
      if (idx === -1) throw new Error("User not found");
      users[idx] = { ...users[idx], ...payload };
      await GitHubDB.saveFile('m_users.json', users, `Edit user ${payload.username}`);
      return { success: true };
    }
    
    case 'deleteUserRecord': {
      const id = args[0];
      let users = await GitHubDB.fetchFile('m_users.json');
      users = users.filter(u => (u.id !== id && u.ID !== id));
      await GitHubDB.saveFile('m_users.json', users, `Delete user ID ${id}`);
      return { success: true };
    }
    
    case 'saveBudgetLive': {
      const [id, annual, actual, remaining, year] = args;
      const budget = await GitHubDB.fetchFile('t_budget.json');
      const idx = budget.findIndex(b => b.id === id);
      if (idx !== -1) {
        budget[idx] = { id, dept: budget[idx].dept, annual, actual, remaining, year };
        await GitHubDB.saveFile('t_budget.json', budget, `Update budget for ${budget[idx].dept}`);
      }
      return { success: true };
    }
    
    case 'deleteBudgetLive': {
      const id = args[0];
      let budget = await GitHubDB.fetchFile('t_budget.json');
      budget = budget.filter(b => b.id !== id);
      await GitHubDB.saveFile('t_budget.json', budget, `Delete budget ID ${id}`);
      return { success: true };
    }
    
    case 'importBudgetLiveCSV': {
      const csvText = args[0];
      const budget = await GitHubDB.fetchFile('t_budget.json');
      const lines = csvText.split('\n');
      let count = 0;
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        const parts = line.split(',');
        if (parts.length >= 2) {
          const dept = parts[0].trim();
          const annual = parseFloat(parts[1]) || 0;
          const idx = budget.findIndex(b => b.dept.toLowerCase() === dept.toLowerCase());
          if (idx !== -1) {
            budget[idx].annual = annual;
            budget[idx].remaining = annual - (budget[idx].actual || 0);
            count++;
          } else {
            const newId = 'B-' + new Date().getTime() + '-' + count;
            budget.push({ id: newId, dept, annual, actual: 0, remaining: annual, year: new Date().getFullYear() });
            count++;
          }
        }
      }
      await GitHubDB.saveFile('t_budget.json', budget, `Import budget CSV`);
      return "Imported/Updated " + count + " budget records successfully.";
    }
    
    case 'submitRequest': {
      const [metadata, items] = args;
      const requests = await GitHubDB.fetchFile('t_requests.json');
      
      const matrix = await GitHubDB.fetchFile('t_approval_matrix.json');
      const matched = matrix.filter(m => {
        const typeMatch = m.type === metadata.type;
        const deptMatch = m.dept === 'ALL' || m.dept === metadata.department;
        const amountMatch = parseFloat(metadata.totalNominal) >= m.min && parseFloat(metadata.totalNominal) <= m.max;
        return typeMatch && deptMatch && amountMatch;
      });
      const approvalSteps = matched.length ? matched[0].steps : (metadata.type === 'PD' ? ['Project Manager','Finance'] : ['Supervisor','Finance','Project Manager']);
      const firstApprover = approvalSteps[0] || 'None';
      
      const signatures = {};
      if (metadata.type === 'PD') {
        signatures['deptHeadPm'] = { name: '', role: 'Supervisor / Head Department', date: '', status: 'PENDING', signatureText: '' };
        signatures['projectManager'] = { name: metadata.customPm || 'Yohanes Sam', role: 'Project Manager / Operation Manager', date: '', status: 'PENDING', signatureText: '' };
        signatures['financeSite'] = { name: '', role: 'Finance Site', date: '', status: 'PENDING', signatureText: '' };
        signatures['costControl'] = { name: '', role: 'Cost Control', date: '', status: 'PENDING', signatureText: '' };
        signatures['gmDept'] = { name: '', role: 'GM / CFO', date: '', status: 'PENDING', signatureText: '' };
      } else {
        signatures['supervisor'] = { name: '', role: 'Supervisor / Head Department', date: '', status: 'PENDING', signatureText: '' };
        signatures['finance'] = { name: '', role: 'Finance', date: '', status: 'PENDING', signatureText: '' };
        signatures['projectManager'] = { name: '', role: 'Project Manager', date: '', status: 'PENDING', signatureText: '' };
        signatures['costControl'] = { name: '', role: 'Cost Control', date: '', status: 'PENDING', signatureText: '' };
        signatures['gmCfo'] = { name: '', role: 'GM / CFO', date: '', status: 'PENDING', signatureText: '' };
      }
      
      const newId = 'REQ-' + new Date().getTime();
      const year = new Date().getFullYear();
      const month = String(new Date().getMonth() + 1).padStart(2, '0');
      const count = requests.filter(r => r.Type === metadata.type).length + 1;
      const docNumber = `${String(count).padStart(3, '0')}/${metadata.type}/${metadata.department}/${month}/${year}`;
      
      const newRequest = {
        ID: newId,
        id: newId,
        Type: metadata.type,
        DocNumber: docNumber,
        Date: new Date().toISOString().substring(0, 10),
        Department: metadata.department,
        Priority: metadata.priority,
        Subject: metadata.subject,
        Requester: metadata.requester,
        TotalNominal: parseFloat(metadata.totalNominal) || 0,
        Signatures: JSON.stringify(signatures),
        UserFor: metadata.userFor || '',
        Status: 'Pending',
        CurrentApproverRole: firstApprover,
        Items: items
      };
      
      requests.push(newRequest);
      await GitHubDB.saveFile('t_requests.json', requests, `Submit request ${docNumber}`);
      return { success: true, docNumber: docNumber };
    }
    
    case 'createMasterRecord': {
      const [tableName, prefix, payload] = args;
      const records = await GitHubDB.fetchFile(tableName + '.json');
      let count = records.length + 1;
      const existingIds = records.map(r => (r.id || r.ID || '').toString());
      let idValue = prefix + '-' + count;
      while (existingIds.indexOf(idValue) !== -1) {
        count++;
        idValue = prefix + '-' + count;
      }
      payload.ID = idValue;
      payload.id = idValue;
      records.push(payload);
      await GitHubDB.saveFile(tableName + '.json', records, `Create record in ${tableName}`);
      return { success: true, record: payload };
    }
    
    case 'updateMasterRecord': {
      const [tableName, id, payload] = args;
      const records = await GitHubDB.fetchFile(tableName + '.json');
      const idx = records.findIndex(r => (r.id === id || r.ID === id));
      if (idx === -1) throw new Error("Record not found");
      records[idx] = { ...records[idx], ...payload };
      await GitHubDB.saveFile(tableName + '.json', records, `Update record in ${tableName}`);
      return { success: true };
    }
    
    case 'deleteMasterRecord': {
      const [tableName, id] = args;
      let records = await GitHubDB.fetchFile(tableName + '.json');
      records = records.filter(r => (r.id !== id && r.ID !== id));
      await GitHubDB.saveFile(tableName + '.json', records, `Delete record in ${tableName}`);
      return { success: true };
    }
    
    case 'loginUser': {
      const [username, password] = args;
      const users = await GitHubDB.fetchFile('m_users.json');
      const inputUserNorm = username ? username.toString().toLowerCase().trim().replace(/\s+/g, '.') : '';
      let foundUser = null;
      for (let i = 0; i < users.length; i++) {
        const u = users[i];
        const rawUsername = u.username || u.Username || '';
        const dbUserNorm = rawUsername.toString().toLowerCase().trim().replace(/\s+/g, '.');
        if (dbUserNorm && dbUserNorm === inputUserNorm) {
          const dbPass = (u.password || u.Password || '').toString();
          const inputPass = password ? password.toString() : '';
          if (dbPass === inputPass) {
            foundUser = {
              id: u.id || u.ID,
              username: u.username || u.Username,
              fullname: u.name || u.Fullname,
              role: u.role || u.Role,
              dept: u.dept || u.Department || u.Dept,
              signature: u.signature || u.Signature,
              status: u.status || u.Status || 'Active'
            };
            break;
          }
        }
      }
      if (foundUser) {
        if (foundUser.status === 'Inactive') {
          return { success: false, error: 'Akun Anda dinonaktifkan.' };
        }
        return { success: true, user: foundUser };
      } else {
        return { success: false, error: 'Username atau password salah!' };
      }
    }
    
    default:
      throw new Error("Action not supported locally via GitHub DB: " + action);
  }
}
'@

# Replace standard Apps Script API interceptor at the top with GitHub DB Interceptor
$interceptorPattern = "(?s)<script>\s*// API FALLBACK INTERCEPTOR FOR VERCEL DEPLOYMENT.*?\n\n/\*\*"
$scriptContent = $scriptContent -replace $interceptorPattern, ("<script>`n" + $githubInterceptor + "`n`n/**")

# Combine files
Write-Host "Bundling Stylesheet.html..." -ForegroundColor Cyan
$indexContent = $indexContent.Replace("<?!= include('Stylesheet'); ?>", $styleContent)

Write-Host "Bundling JavaScript.html..." -ForegroundColor Cyan
$indexContent = $indexContent.Replace("<?!= include('JavaScript'); ?>", $scriptContent)

# Write bundled HTML for GitHub DB
$outHtmlPath = Join-Path $distDir "index.html"
Set-Content -Path $outHtmlPath -Value $indexContent -Encoding utf8
Write-Host "Bundled GitHub DB file written: $outHtmlPath" -ForegroundColor Green

# Create README.md
$readmePath = Join-Path $distDir "README.md"
$readmeContent = @"
# Bara Indah Sinergi Group - Workflow Approval Web App (GitHub DB Version)

Aplikasi workflow approval ini dirancang sebagai website mandiri yang siap di-deploy ke Vercel dengan database berbasis file JSON yang disimpan langsung di repositori GitHub Anda.

## Struktur File
- `index.html`: File frontend gabungan (HTML + CSS + JS) untuk di-deploy ke Vercel atau GitHub Pages.
- `db/`: Folder berisi file database JSON default yang wajib Anda unggah ke repositori GitHub Anda.

## Langkah-Langkah Deploy ke GitHub & Vercel

### 1. Buat Repositori GitHub Baru
1. Buat sebuah repositori baru di GitHub (bisa bertipe **Public** atau **Private**).
2. Unggah file `index.html` dan folder `db/` beserta isinya ke root repositori Anda.

### 2. Dapatkan GitHub Personal Access Token (PAT)
Aplikasi memerlukan token untuk menulis data (commit file) ke repositori Anda secara aman.
1. Masuk ke GitHub, klik foto profil Anda di kanan atas > **Settings**.
2. Gulir ke bawah dan klik **Developer Settings** > **Personal Access Tokens** > **Tokens (classic)**.
3. Klik **Generate new token (classic)**.
4. Beri nama token (misal: "workflow-db-token").
5. Centang opsi scope **"repo"** (atau jika repositori publik, cukup berikan izin akses write).
6. Klik **Generate token** dan salin kodenya (formatnya seperti `ghp_...`). *Catat kode ini karena kode hanya ditampilkan sekali.*

### 3. Deploy ke Vercel
1. Masuk ke dashboard **Vercel** (`vercel.com`).
2. Buat proyek baru (**New Project**) dan hubungkan ke repositori GitHub yang baru saja Anda buat.
3. Klik **Deploy**. Vercel akan menyajikan aplikasi Anda sebagai website statis.
4. Buka URL web hasil deploy Vercel Anda di browser.

### 4. Hubungkan Aplikasi Vercel dengan Repositori GitHub
1. Saat pertama kali memuat halaman web Vercel Anda, popup **GitHub Database Connection** akan otomatis muncul.
2. Masukkan detail repositori Anda:
   - **GitHub Owner**: Username GitHub Anda (atau nama organisasi).
   - **GitHub Repository Name**: Nama repositori GitHub yang baru Anda buat.
   - **GitHub Branch**: Cabang repositori Anda (umumnya `main`).
   - **GitHub Personal Access Token (PAT)**: Token `ghp_...` yang telah Anda buat di Langkah 2.
3. Klik **Simpan Koneksi**.
4. Halaman akan memuat ulang, membaca data pengguna dari repositori Anda, dan aplikasi siap digunakan sepenuhnya!
5. Untuk mengubah koneksi atau token di masa mendatang, klik ikon **Settings (sliders)** di bar kanan atas halaman.
"@

Set-Content -Path $readmePath -Value $readmeContent -Encoding utf8
Write-Host "README.md created: $readmePath" -ForegroundColor Green
Write-Host "Build complete! Upload files inside: $distDir" -ForegroundColor Green

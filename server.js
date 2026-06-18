// server.js
// Standalone Local Node.js Server for Workflow Approval Web App
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static(__dirname)); // Serves static files in root (index.html)

// Helper: Read JSON database file
function readDbFile(filename) {
  const filePath = path.join(__dirname, 'db', filename);
  if (!fs.existsSync(filePath)) {
    return [];
  }
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    console.error(`Error reading ${filename}:`, err);
    return [];
  }
}

// Helper: Write JSON database file
function writeDbFile(filename, data) {
  const dbDir = path.join(__dirname, 'db');
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir);
  }
  const filePath = path.join(dbDir, filename);
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    return true;
  } catch (err) {
    console.error(`Error writing to ${filename}:`, err);
    return false;
  }
}

// API Action Router
app.post('/api/action', async (req, res) => {
  const { action, args } = req.body;
  
  try {
    let result;
    switch (action) {
      case 'getDropdownData': {
        const departments = readDbFile('m_departments.json');
        const coas = readDbFile('m_coas.json');
        result = { departments, coas };
        break;
      }
      
      case 'getDashboardData': {
        const requests = readDbFile('t_requests.json');
        const budget = readDbFile('t_budget.json');
        const logs = readDbFile('t_activity_log.json');
        result = { requests, budget, logs };
        break;
      }
      
      case 'getApprovalRequests': {
        const role = args[0];
        const requests = readDbFile('t_requests.json');
        const users = readDbFile('m_users.json');
        
        const pmUser = users.find(u => u.role === 'Project Manager');
        const isPmLeave = pmUser && pmUser.status === 'Cuti';
        
        result = requests.filter(req => {
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
        break;
      }
      
      case 'processApproval': {
        const [requestId, actionType, role, comment, userName] = args;
        const requests = readDbFile('t_requests.json');
        const budget = readDbFile('t_budget.json');
        const logs = readDbFile('t_activity_log.json');
        const users = readDbFile('m_users.json');
        
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
        const matrix = readDbFile('t_approval_matrix.json');
        
        const matched = matrix.filter(m => {
          const typeMatch = m.type === request.Type;
          const deptMatch = m.dept === 'ALL' || m.dept === request.Department;
          const amountMatch = parseFloat(request.TotalNominal) >= m.min && parseFloat(request.TotalNominal) <= m.max;
          return typeMatch && deptMatch && amountMatch;
        });
        const approvalSteps = matched.length ? matched[0].steps : (request.Type === 'PD' ? ['Project Manager','Finance'] : ['Supervisor','Finance','Project Manager']);
        
        function getSigKey(roleVal) {
          const mapping = {
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
        
        let key = getSigKey(finalRole);
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
          
          const currentStepIndex = approvalSteps.indexOf(finalRole);
          let nextApprover = '';
          let nextStatus = 'Pending';
          
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
            ip: req.ip || '127.0.0.1'
          });
          
          writeDbFile('t_requests.json', requests);
          writeDbFile('t_budget.json', budget);
          writeDbFile('t_activity_log.json', logs);
          
          result = { success: true, status: nextStatus };
          
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
            ip: req.ip || '127.0.0.1'
          });
          
          writeDbFile('t_requests.json', requests);
          writeDbFile('t_activity_log.json', logs);
          
          result = { success: true, status: 'Rejected' };
        }
        break;
      }
      
      case 'getDocumentHistory': {
        const requests = readDbFile('t_requests.json');
        result = requests.map(req => {
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
        break;
      }
      
      case 'saveUserSignature': {
        const [username, sigDataUrl] = args;
        const users = readDbFile('m_users.json');
        const idx = users.findIndex(u => u.username === username);
        if (idx === -1) throw new Error("User not found");
        users[idx].signature = sigDataUrl;
        writeDbFile('m_users.json', users);
        result = { success: true };
        break;
      }
      
      case 'createUserRecord': {
        const payload = args[0];
        const users = readDbFile('m_users.json');
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
        writeDbFile('m_users.json', users);
        result = { success: true, record: payload };
        break;
      }
      
      case 'editUserRecord': {
        const [id, payload] = args;
        const users = readDbFile('m_users.json');
        const idx = users.findIndex(u => (u.id === id || u.ID === id));
        if (idx === -1) throw new Error("User not found");
        users[idx] = { ...users[idx], ...payload };
        writeDbFile('m_users.json', users);
        result = { success: true };
        break;
      }
      
      case 'deleteUserRecord': {
        const id = args[0];
        let users = readDbFile('m_users.json');
        users = users.filter(u => (u.id !== id && u.ID !== id));
        writeDbFile('m_users.json', users);
        result = { success: true };
        break;
      }
      
      case 'saveBudgetLive': {
        const [id, annual, actual, remaining, year] = args;
        const budget = readDbFile('t_budget.json');
        const idx = budget.findIndex(b => b.id === id);
        if (idx !== -1) {
          budget[idx] = { id, dept: budget[idx].dept, annual, actual, remaining, year };
          writeDbFile('t_budget.json', budget);
        }
        result = { success: true };
        break;
      }
      
      case 'deleteBudgetLive': {
        const id = args[0];
        let budget = readDbFile('t_budget.json');
        budget = budget.filter(b => b.id !== id);
        writeDbFile('t_budget.json', budget);
        result = { success: true };
        break;
      }
      
      case 'importBudgetLiveCSV': {
        const csvText = args[0];
        const budget = readDbFile('t_budget.json');
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
        writeDbFile('t_budget.json', budget);
        result = "Imported/Updated " + count + " budget records successfully.";
        break;
      }
      
      case 'submitRequest': {
        const [metadata, items] = args;
        const requests = readDbFile('t_requests.json');
        const matrix = readDbFile('t_approval_matrix.json');
        
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
        writeDbFile('t_requests.json', requests);
        result = { success: true, docNumber: docNumber };
        break;
      }
      
      case 'createMasterRecord': {
        const [tableName, prefix, payload] = args;
        const records = readDbFile(tableName + '.json');
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
        writeDbFile(tableName + '.json', records);
        result = { success: true, record: payload };
        break;
      }
      
      case 'updateMasterRecord': {
        const [tableName, id, payload] = args;
        const records = readDbFile(tableName + '.json');
        const idx = records.findIndex(r => (r.id === id || r.ID === id));
        if (idx === -1) throw new Error("Record not found");
        records[idx] = { ...records[idx], ...payload };
        writeDbFile(tableName + '.json', records);
        result = { success: true };
        break;
      }
      
      case 'deleteMasterRecord': {
        const [tableName, id] = args;
        let records = readDbFile(tableName + '.json');
        records = records.filter(r => (r.id !== id && r.ID !== id));
        writeDbFile(tableName + '.json', records);
        result = { success: true };
        break;
      }
      
      case 'loginUser': {
        const [username, password] = args;
        const users = readDbFile('m_users.json');
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
            result = { success: false, error: 'Akun Anda dinonaktifkan.' };
          } else {
            result = { success: true, user: foundUser };
          }
        } else {
          result = { success: false, error: 'Username atau password salah!' };
        }
        break;
      }
      
      default:
        throw new Error("Action not supported by local server: " + action);
    }
    
    res.json({ success: true, data: result });
  } catch (err) {
    console.error(`Error executing action ${action}:`, err);
    res.json({ success: false, error: err.message || err.toString() });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`=======================================================`);
  console.log(` Bara Indah Sinergi - Workflow Approval Local Server   `);
  console.log(` Running on port ${PORT}...                            `);
  console.log(`=======================================================`);
  console.log(`- Local Access:  http://localhost:${PORT}`);
  
  // Print local network IP addresses
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        console.log(`- Network Access: http://${net.address}:${PORT}`);
      }
    }
  }
  console.log(`=======================================================`);
});

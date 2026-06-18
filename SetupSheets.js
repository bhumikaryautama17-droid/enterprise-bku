/**
 * Setup and Seed Database Tables inside Google Sheets
 */
function setupSheets() {
  var ss = getSpreadsheet();
  
  // Define sheets and their headers
  var sheetsDef = {
    't_requests': ['ID', 'Type', 'DocNumber', 'Date', 'Department', 'Priority', 'InventoryType', 'PurchaseCategory', 'Subject', 'Requester', 'TotalNominal', 'Status', 'CurrentApproverRole', 'CreatedAt', 'Signatures', 'UserFor', 'Attachment', 'AttachmentName', 'BudgetCapture'],
    't_request_items': ['ID', 'RequestId', 'COA', 'PartNumber', 'Description', 'CostElement', 'Quantity', 'UoM', 'Price', 'Total'],
    't_approval_matrix': ['ID', 'DocType', 'Department', 'MinAmount', 'MaxAmount', 'Steps'],
    't_budget': ['ID', 'Department', 'Project', 'Year', 'AnnualBudget', 'ActualBudget'],
    't_audit_log': ['ID', 'Timestamp', 'User', 'Activity', 'Module', 'DocNumber', 'IPAddress'],
    'm_departments': ['ID', 'Code', 'Name'],
    'm_projects': ['ID', 'Code', 'Name'],
    'm_coas': ['ID', 'Code', 'Name'],
    'm_cost_elements': ['ID', 'Code', 'Name'],
    'm_users': ['ID', 'Username', 'Fullname', 'Role', 'Department', 'Password', 'Signature', 'Status']
  };
  
  // Create sheets if not exists and set headers
  for (var name in sheetsDef) {
    var sheet = ss.getSheetByName(name);
    var isNew = false;
    if (!sheet) {
      sheet = ss.insertSheet(name);
      isNew = true;
    }
    // Only set headers if it's newly created or completely empty
    if (isNew || sheet.getLastRow() === 0) {
      sheet.clear();
      var headers = sheetsDef[name];
      sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
      sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold').setBackground('#2a3b5c').setFontColor('#ffffff');
    }
  }
  
  // Clean default Sheet1 if exists
  var sheet1 = ss.getSheetByName('Sheet1');
  if (sheet1) {
    try {
      ss.deleteSheet(sheet1);
    } catch(e) {}
  }
  
  // Seed master data if empty
  seedMasterData(ss);
}

function seedMasterData(ss) {
  // 1. Seed Departments
  var deptSheet = ss.getSheetByName('m_departments');
  if (deptSheet.getLastRow() <= 1) {
    var depts = [
      ['DEPT-1', 'HRGA', 'Human Resources & General Affairs'],
      ['DEPT-2', 'QAQC', 'Quality Assurance & Quality Control'],
      ['DEPT-3', 'SHE', 'Safety, Health & Environment'],
      ['DEPT-4', 'Engineering', 'Engineering Department'],
      ['DEPT-5', 'Plant', 'Plant Operation'],
      ['DEPT-6', 'External', 'External Affairs'],
      ['DEPT-7', 'Eksplorasi', 'Eksplorasi & Geological']
    ];
    deptSheet.getRange(2, 1, depts.length, 3).setValues(depts);
  }
  
  // 2. Seed Projects
  var projSheet = ss.getSheetByName('m_projects');
  if (projSheet.getLastRow() <= 1) {
    var projs = [
      ['PROJ-1', 'PROJ-CRM', 'CRM System Development'],
      ['PROJ-2', 'PROJ-MSR', 'MSR Safety Procurement'],
      ['PROJ-3', 'PROJ-EXPL', 'Sko Coal Drilling Plan']
    ];
    projSheet.getRange(2, 1, projs.length, 3).setValues(projs);
  }
  
  // 3. Seed/Sync Users
  syncUsers(ss);
  
  // 4. Seed COA
  var coaSheet = ss.getSheetByName('m_coas');
  if (coaSheet.getLastRow() <= 1) {
    var coas = [
      ['COA-1', '610-02-03-001', 'Kipas Angin Regency 16 Inch'],
      ['COA-2', '610-02-03-002', 'Stop Kontak Arde 5 Meter'],
      ['COA-3', '610-02-05-001', 'Termometer Digital'],
      ['COA-4', '610-02-05-002', 'Safety Helmet Yellow'],
      ['COA-5', '610-02-06-001', 'Kertas A4 80gr Sinar Dunia']
    ];
    coaSheet.getRange(2, 1, coas.length, 3).setValues(coas);
  }
  
  // 5. Seed Cost Elements
  var ceSheet = ss.getSheetByName('m_cost_elements');
  if (ceSheet.getLastRow() <= 1) {
    var ces = [
      ['CE-1', '612.01.04', 'Office Supplies'],
      ['CE-2', '612.01.05', 'Tool Equipment'],
      ['CE-3', '612.02.01', 'Safety Equipment']
    ];
    ceSheet.getRange(2, 1, ces.length, 3).setValues(ces);
  }
  
  // 6. Seed Approval Matrix
  var matrixSheet = ss.getSheetByName('t_approval_matrix');
  if (matrixSheet.getLastRow() <= 1) {
    var matrix = [
      ['AM-1', 'PD', 'ALL', 0, 99999999999, 'Project Manager, Finance'],
      ['AM-2', 'PR', 'ALL', 0, 99999999999, 'Supervisor, Finance, Project Manager']
    ];
    matrixSheet.getRange(2, 1, matrix.length, 6).setValues(matrix);
  }
  
  // 7. Seed Budgets
  var budgetSheet = ss.getSheetByName('t_budget');
  if (budgetSheet.getLastRow() <= 1) {
    var budgets = [
      ['B-1', 'HRGA', 'PROJ-CRM', 2026, 650000000, 420000000],
      ['B-2', 'QAQC', 'PROJ-CRM', 2026, 320000000, 150000000],
      ['B-3', 'SHE', 'PROJ-MSR', 2026, 180000000, 80000000],
      ['B-4', 'Engineering', 'PROJ-CRM', 2026, 2100000000, 1200000000],
      ['B-5', 'Plant', 'PROJ-CRM', 2026, 4200000000, 2800000000],
      ['B-6', 'External', 'PROJ-CRM', 2026, 252000000, 110000000],
      ['B-7', 'Eksplorasi', 'PROJ-EXPL', 2026, 2000000000, 1400000000]
    ];
    budgetSheet.getRange(2, 1, budgets.length, 6).setValues(budgets);
  }
  
  // 8. Seed t_requests with initial items
  var reqSheet = ss.getSheetByName('t_requests');
  if (reqSheet.getLastRow() <= 1) {
    var today = new Date();
    var lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 15);
    var dateStringToday = today.toISOString().substring(0, 10);
    var dateStringLast = lastMonth.toISOString().substring(0, 10);
    
    var sigsPR1 = {
      user: { name: 'Muh Idul Adhan Yusuf', role: 'User', date: lastMonth.toISOString(), status: 'SUBMITTED', signatureText: 'Muh Idul Adhan Yusuf' },
      supervisor: { name: 'Mona Asrani', role: 'Supervisor', date: lastMonth.toISOString(), status: 'APPROVED', signatureText: '[e-Signed: Mona Asrani]' },
      finance: { name: '', role: 'Finance', date: '', status: 'PENDING', signatureText: '' },
      projectManager: { name: '', role: 'Project Manager', date: '', status: 'PENDING', signatureText: '' }
    };
    
    var sigsPD2 = {
      user: { name: 'Mona Asrani', role: 'User', date: today.toISOString(), status: 'SUBMITTED', signatureText: 'Mona Asrani' },
      deptHeadPm: { name: '', role: 'Dept Head / PM', date: '', status: 'PENDING', signatureText: '' },
      financeSite: { name: '', role: 'Finance Site', date: '', status: 'PENDING', signatureText: '' }
    };
    
    var requests = [
      [
        'REQ-1', 'PR', 'PR-2026-00045', dateStringLast, 'HRGA', 'P1', 
        'NON STOCK', 'Office Equipment', 'Kebutuhan Kipas Angin Regency Periode Maret 2026',
        'Muh Idul Adhan Yusuf', 995000, 'Pending', 'Finance', lastMonth.toISOString(), 
        JSON.stringify(sigsPR1), 'Kebutuhan Kipas Angin Regency Periode Maret 2026'
      ],
      [
        'REQ-2', 'PD', 'PD-2026-00012', dateStringToday, 'HRGA', 'P2', 
        '', '', 'Kebutuhan Operasional Proyek Maret 2026', 
        'Mona Asrani', 15450000, 'Pending', 'Project Manager', today.toISOString(), 
        JSON.stringify(sigsPD2), 'Dana operasional operasional proyek lapangan'
      ],
      [
        'REQ-3', 'PR', 'PR-2026-00046', dateStringToday, 'QAQC', 'P3', 
        'STOCK', 'Tools', 'Pembelian Alat Lab & Termometer', 
        'Yusril', 3250000, 'Approved', 'None', today.toISOString(), 
        JSON.stringify({
          user: { name: 'Yusril', role: 'User', date: today.toISOString(), status: 'SUBMITTED', signatureText: 'Yusril' },
          supervisor: { name: 'Yusril', role: 'Supervisor', date: today.toISOString(), status: 'APPROVED', signatureText: '[e-Signed: Yusril]' },
          finance: { name: 'Putri Amalia', role: 'Finance', date: today.toISOString(), status: 'APPROVED', signatureText: '[e-Signed: Putri Amalia]' },
          projectManager: { name: 'Rosalia Natalia', role: 'Project Manager', date: today.toISOString(), status: 'APPROVED', signatureText: '[e-Signed: Rosalia Natalia]' }
        }), 'Penyediaan termometer digital proyek QAQC'
      ]
    ];
    
    reqSheet.getRange(2, 1, requests.length, requests[0].length).setValues(requests);
    
    // Seed items
    var itemsSheet = ss.getSheetByName('t_request_items');
    var items = [
      ['ITEM-1', 'REQ-1', '610-02-03-001', 'KIP-REG-16', 'Kipas Angin Regency 16 Inch', '612.01.04', 5, 'Unit', 150000, 750000],
      ['ITEM-2', 'REQ-1', '610-02-03-002', 'EXT-CORD-5M', 'Stop Kontak Arde 5 Meter', '612.01.04', 5, 'Unit', 49000, 245000],
      ['ITEM-3', 'REQ-2', '610-02-06-001', 'ATK-A4-SD', 'Kertas A4 80gr Sinar Dunia', '612.01.04', 308, 'Box', 50000, 15450000],
      ['ITEM-4', 'REQ-3', '610-02-05-001', 'TERM-DIG', 'Termometer Digital', '612.01.05', 10, 'Unit', 325000, 3250000]
    ];
    itemsSheet.getRange(2, 1, items.length, items[0].length).setValues(items);
  }
  
  // 9. Seed audit trail
  var logSheet = ss.getSheetByName('t_audit_log');
  if (logSheet.getLastRow() <= 1) {
    var todayStr = new Date().toISOString();
    var logs = [
      ['LOG-1', todayStr, 'Muh Idul Adhan Yusuf', 'Create PR', 'Requests', 'PR-2026-00045', '192.168.10.12'],
      ['LOG-2', todayStr, 'Mona Asrani', 'Approved at Supervisor', 'Approval', 'PR-2026-00045', '192.168.10.13'],
      ['LOG-3', todayStr, 'Mona Asrani', 'Create PD', 'Requests', 'PD-2026-00012', '192.168.10.13'],
      ['LOG-4', todayStr, 'Yusril', 'Create PR', 'Requests', 'PR-2026-00046', '192.168.10.15'],
      ['LOG-5', todayStr, 'Putri Amalia', 'Approved at Finance', 'Approval', 'PR-2026-00046', '192.168.10.14']
    ];
    logSheet.getRange(2, 1, logs.length, logs[0].length).setValues(logs);
  }
}

/**
 * Synchronize target users list to the m_users sheet,
 * ensuring all usernames and passwords are up-to-date while preserving user signatures.
 */
function syncUsers(ss) {
  var sheet = ss.getSheetByName('m_users');
  if (!sheet) return;
  
  var targetUsers = [
    ['USR-1', 'mona.asrani', 'Mona Asrani', 'Supervisor', 'HRGA', 'BARAindah@2026', '', 'Active'],
    ['USR-2', 'rosalia.natalia', 'Rosalia Natalia', 'Project Manager', 'Management', 'BARAindah@2026', '', 'Active'],
    ['USR-3', 'putri.amalia', 'Putri Amalia', 'Finance', 'Finance', 'BARAindah@2026', '', 'Active'],
    ['USR-4', 'rosmina.rabbang', 'Rosmina Rabbang', 'Supervisor', 'SHE', 'BARAindah@2026', '', 'Active'],
    ['USR-5', 'erwin.eka', 'Erwin Eka', 'Supervisor', 'External', 'BARAindah@2026', '', 'Active'],
    ['USR-6', 'yusril', 'Yusril', 'Supervisor', 'QAQC', 'BARAindah@2026', '', 'Active'],
    ['USR-7', 'roymon.biang', 'Roymon Biang', 'Supervisor', 'Engineering', 'BARAindah@2026', '', 'Active'],
    ['USR-8', 'muh.said', 'Muh. Said', 'Supervisor', 'Plant', 'BARAindah@2026', '', 'Active'],
    ['USR-9', 'laode.rusman', 'Laode Rusman', 'Supervisor', 'Eksplorasi', 'BARAindah@2026', '', 'Active'],
    ['USR-10', 'idul.yusuf', 'Muh Idul Adhan Yusuf', 'User', 'HRGA', 'BARAindah@2026', '', 'Active'],
    ['USR-11', 'saiful.basri', 'Saiful Basri', 'User', 'SHE', 'BARAindah@2026', '', 'Active'],
    ['USR-12', 'admin', 'System Administrator', 'Administrator', 'IT', 'BARAindah@2026', '', 'Active']
  ];
  
  var data = sheet.getDataRange().getValues();
  var idToRowIndex = {};
  for (var r = 1; r < data.length; r++) {
    var rawId = data[r] && data[r][0];
    var id = (rawId !== undefined && rawId !== null) ? rawId.toString().trim() : '';
    if (id) {
      idToRowIndex[id] = r + 1; // 1-based sheet row index
    }
  }
  
  for (var i = 0; i < targetUsers.length; i++) {
    var target = targetUsers[i];
    var id = target[0];
    var rowIndex = idToRowIndex[id];
    if (!rowIndex) {
      // Append new user if USR-ID is missing
      sheet.appendRow(target);
    }
  }
}

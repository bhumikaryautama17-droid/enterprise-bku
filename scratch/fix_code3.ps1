$bph = Get-Content "scratch\buildPaperHTML.txt" -Raw
$bph = $bph -replace 'function buildPaperHTML\(doc\) \{', 'function buildPaperHTMLServer(doc) {
  var usersList = getSheetDataAsObjects("m_users");'

$bph = $bph -replace 'DB\.users\.find\(u => u\.role === role && \(dept \? u\.dept === dept : true\)\)', 'usersList.filter(function(u) { return u.Role === role && (dept ? u.Department === dept : true); })[0]'
$bph = $bph -replace 'DB\.users\.find\(u => u\.name === signerName\)', 'usersList.filter(function(u) { return u.Fullname === signerName; })[0]'
$bph = $bph -replace 'dbUser\.signature', 'dbUser.Signature'

$bph = $bph -replace 'genSVGSig\(sigObj\.name\)\.replace\(''class="esig"'',''style="width:110px;height:38px"''\)\.replace\(''stroke:var\(--cy\)'''',''stroke:#1565c0''\)', '''<span style="font-size:9px; font-weight:bold; color:#0056b3;">[e-Signed]</span>'''

$generatePDF = @"
function generatePDF(requestId) {
  try {
    var request = getRequestDetails(requestId);
    if (!request) return { success: false, error: 'Document not found' };
    
    var doc = {
      type: request.metadata.type,
      docNo: request.metadata.docNumber,
      date: request.metadata.date,
      dept: request.metadata.department,
      priority: request.metadata.priority,
      inventoryType: request.metadata.inventoryType,
      subj: request.metadata.subject,
      reqName: request.metadata.requester,
      nominal: request.metadata.nominal,
      attachment: request.metadata.attachment,
      attachmentName: request.metadata.attachmentName,
      items: request.items,
      sigs: {}
    };
    
    try { doc.sigs = JSON.parse(request.signatures); } catch(e) {}
    
    var htmlContent = buildPaperHTMLServer(doc);
    
    var blob = Utilities.newBlob(htmlContent, 'text/html', 'document.html');
    var pdfBlob = blob.getAs('application/pdf');
    pdfBlob.setName(request.metadata.docNumber.replace(/\//g, '_') + '.pdf');
    var base64 = Utilities.base64Encode(pdfBlob.getBytes());
    
    return {
      success: true,
      pdfBase64: 'data:application/pdf;base64,' + base64,
      fileName: request.metadata.docNumber.replace(/\//g, '_') + '.pdf'
    };
  } catch (e) {
    return { success: false, error: e.toString() };
  }
}

"@

$newCode = $generatePDF + "`n" + $bph

$lines = Get-Content Code.js
$newLines = @()
for ($i=0; $i -lt 1192; $i++) {
    $newLines += $lines[$i]
}
$newLines += $newCode
for ($i=3474; $i -lt $lines.Length; $i++) {
    $newLines += $lines[$i]
}

$newLines -join "`n" | Out-File Code.js -Encoding UTF8
Write-Host "Code.js fixed!"

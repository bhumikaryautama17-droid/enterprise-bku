const fs = require('fs');

const indexHtml = fs.readFileSync('index_local_preview.html', 'utf8');

// Match the PNG base64 for PR
const pngMatch = indexHtml.match(/<img src="(data:image\/png;base64,[^"]+)"[^>]*>\s*<div[^>]*>PT\. BHUMI KARYA UTAMA<\/div>/);
const pngBase64 = pngMatch ? pngMatch[1] : '';

let codeJs = fs.readFileSync('Code.js', 'utf8');

const startMarker = '<td style="width: 25%; text-align: center;">\' +';
const endMarker = '<td style="width: 45%; text-align: center;">\' +';

const startIndex = codeJs.indexOf(startMarker);
const endIndex = codeJs.indexOf(endMarker);

if (startIndex !== -1 && endIndex !== -1 && pngBase64) {
  const snippet = codeJs.substring(startIndex, endIndex);
  const jpegMatch = snippet.match(/data:image\/jpeg;base64,[a-zA-Z0-9+/=]+/);
  const jpegBase64 = jpegMatch ? jpegMatch[0] : '';

  if (jpegBase64) {
    const replacement = `<td style="width: 25%; text-align: center;">' +
        '<img src="' + (data.type === 'PD' ? '${jpegBase64}' : '${pngBase64}') + '" style="max-height:65px; max-width:100%; object-fit:contain; display:block; margin:0 auto 3px auto;" />' +\\r\\n
        '<div style="font-size:8.5px;color:#444;text-align:center;line-height:1.4;font-weight:bold;">' + (data.type === 'PD' ? 'PT. BARA INDAH SINERGI' : 'PT. BHUMI KARYA UTAMA') + '</div>' +\\r\\n
        '</td>' +\\r\\n        '`;
    
    codeJs = codeJs.substring(0, startIndex) + replacement + codeJs.substring(endIndex);
    fs.writeFileSync('Code.js', codeJs);
    console.log('Fixed Code.js successfully.');
  } else {
    console.log('Could not find JPEG base64 in Code.js snippet');
  }
} else {
  console.log('Could not find markers or PNG base64', !!pngBase64, startIndex, endIndex);
}

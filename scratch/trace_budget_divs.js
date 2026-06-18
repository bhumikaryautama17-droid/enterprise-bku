const fs = require('fs');
const lines = fs.readFileSync('index_cpanel.html', 'utf8').split('\n');

let stack = [];
for (let i = 0; i < 2000; i++) {
  const line = lines[i];
  let idx = 0;
  
  while (true) {
    const startIdx = line.indexOf('<', idx);
    if (startIdx === -1) break;
    const endIdx = line.indexOf('>', startIdx);
    if (endIdx === -1) break;
    
    const tagContent = line.substring(startIdx + 1, endIdx).trim();
    idx = endIdx + 1;
    
    if (tagContent.startsWith('!--') || tagContent.endsWith('/') || tagContent.startsWith('meta') || tagContent.startsWith('link') || tagContent.startsWith('input') || tagContent.startsWith('img') || tagContent.startsWith('hr') || tagContent.startsWith('br')) {
      continue;
    }
    
    const isClose = tagContent.startsWith('/');
    const cleanTag = isClose ? tagContent.substring(1).trim() : tagContent;
    const match = cleanTag.match(/^([a-zA-Z0-9\-]+)/);
    if (!match) continue;
    const tagName = match[1].toLowerCase();
    
    if (tagName === 'div') {
      if (isClose) {
        const popped = stack.pop();
        if (i >= 1670 && i <= 1685) {
          console.log(`Line ${i + 1}: Closes <div> opened at line ${popped ? popped.line : 'unknown'} (${popped ? popped.content : 'none'})`);
        }
      } else {
        stack.push({ line: i + 1, content: line.substring(startIdx, endIdx + 1) });
      }
    }
  }
}

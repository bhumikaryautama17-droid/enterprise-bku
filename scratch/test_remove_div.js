const fs = require('fs');
const lines = fs.readFileSync('index_cpanel.html', 'utf8').split('\n');

// Remove line 1678 (index 1677)
lines.splice(1677, 1);

let stack = [];
const scriptStartLine = lines.findIndex((l, idx) => idx > 2000 && l.includes('<script>'));
console.log('Script tag starts at line:', scriptStartLine + 1);

for (let i = 0; i < scriptStartLine; i++) {
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
        if (stack.length === 0) {
          console.log(`Line ${i + 1}: Error - Extra closing </div>`);
        } else {
          stack.pop();
        }
      } else {
        stack.push({ line: i + 1, content: line.substring(startIdx, endIdx + 1) });
      }
    }
  }
}

if (stack.length > 0) {
  console.log('\nUnclosed <div> tags:');
  stack.forEach(s => {
    console.log(`  Line ${s.line}: ${s.content}`);
  });
} else {
  console.log('\nNo unclosed <div> tags found!');
}

const fs = require('fs');

const fileContent = fs.readFileSync('C:/Users/ASUS/Projects/MediQueue/mediqueue-backend/public/hospital.html', 'utf8');
let fixedContent = fileContent;

// Mappings obtained by directly copying from bad_lines.txt to ensure exact JS string literal matching.
const replacements = [
  ['â† ', '←'],
  ['ðŸ‘¨â€ âš•ï¸ ', '👨‍⚕️'],
  ['ðŸ ¢', '🏥'],
  ['âš™ï¸ ', '⚙️'],
  ['ðŸ” ', '🔍'],
  ['ðŸ–¨ï¸ ', '🖨️'],
  ['âœ ï¸ ', '✏️'],
  ['â”€â”€', '──'],
  ['â”€', '─'],
  ['â• â• ', '══'],
  ['â• ', '═'],
  ['🔄', '🔄'],
  ['⚠️', '⚠️'],
  ['🗑', '🗑'],
  // also long lines 
  ['<!-- â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• ', '<!-- ══════════════════════════════════════════════'],
  ['â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â•  -->', '═══════════════════════════════════════════════ -->'],
  ['â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â• â•  -->', '═══════════════════════════════════════════════ -->']
];

for (const [bad, good] of replacements) {
    // using split join for global replace
    fixedContent = fixedContent.split(bad).join(good);
}

fs.writeFileSync('C:/Users/ASUS/Projects/MediQueue/mediqueue-backend/public/hospital.html', fixedContent, 'utf8');
console.log('Fixed using array script');

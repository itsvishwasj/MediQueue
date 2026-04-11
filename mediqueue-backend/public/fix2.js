const fs = require('fs');

function fixMojibake(filePath) {
  let text = fs.readFileSync(filePath, 'utf8');

  // The map of bad sequences to correct strings
  const map = {
    'â† ': '←',
    'ðŸ‘¨â€ âš•ï¸ ': '👨‍⚕️',
    'ðŸ ¢': '🏥',
    'âš™ï¸ ': '⚙️',
    'ðŸ” ': '🔍',
    'ðŸ–¨ï¸ ': '🖨️',
    'âœ ï¸ ': '✏️',
    'â”€â”€': '──',
    'â”€': '─',
    'â• â• ': '══',
    'â• ': '═',
    '🔄': '🔄',
    '⚠️': '⚠️',
    '🗑': '🗑'
  };

  for (const [bad, good] of Object.entries(map)) {
    text = text.split(bad).join(good);
  }

  return text;
}

const targetFile = 'C:/Users/ASUS/Projects/MediQueue/mediqueue-backend/public/hospital.html';
const fixed = fixMojibake(targetFile);

// Overwrite the file directly
fs.writeFileSync(targetFile, fixed, 'utf8');
console.log('Fixed correctly directly to hospital.html');

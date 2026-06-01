// Package the src/ game folder into a .love file (zip with main.lua at root).
// The output filename is derived from package.json "name" field.
// Used by `npm run build` so the love.js input is deterministic.
const path = require('path');
const fs = require('fs');
const AdmZip = require('adm-zip');

// __dirname is src/love2d4me/scripts/ — project root is three levels up
const root = path.join(__dirname, '..', '..', '..');
const gameDir = path.join(root, 'src');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const loveName = (pkg.lovefile || pkg.name || 'game') + '.love';
const out = path.join(root, loveName);

fs.rmSync(out, { force: true });
const zip = new AdmZip();
zip.addLocalFolder(gameDir);
zip.writeZip(out);
console.log('packed ' + out + ' (' + (fs.statSync(out).size / 1048576).toFixed(2) + ' MB)');

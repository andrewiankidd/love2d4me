// Package the src/ game folder into a .love file (zip with main.lua at root).
// The output filename is derived from package.json "name" field.
// In dev mode (sibling love2d4me repo exists), uses the local copy instead of
// the submodule so you can test web builds without committing the submodule.
const path = require('path');
const fs = require('fs');
const AdmZip = require('adm-zip');

const root = path.join(__dirname, '..', '..', '..');
const gameDir = path.join(root, 'src');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const loveName = (pkg.lovefile || pkg.name || 'game') + '.love';
const out = path.join(root, loveName);

const devPath = path.join(root, '..', 'love2d4me');
const devMode = fs.existsSync(path.join(devPath, 'init.lua'));

const DEV_INCLUDE = ['init.lua', 'src', 'scripts', 'assets', 'skins', '.luacheckrc'];

fs.rmSync(out, { force: true });
const zip = new AdmZip();

if (devMode) {
    const entries = fs.readdirSync(gameDir);
    for (const entry of entries) {
        if (entry === 'love2d4me') continue;
        const full = path.join(gameDir, entry);
        if (fs.statSync(full).isDirectory()) {
            zip.addLocalFolder(full, entry);
        } else {
            zip.addLocalFile(full, '');
        }
    }
    for (const entry of DEV_INCLUDE) {
        const full = path.join(devPath, entry);
        if (!fs.existsSync(full)) continue;
        if (fs.statSync(full).isDirectory()) {
            zip.addLocalFolder(full, 'love2d4me/' + entry);
        } else {
            zip.addLocalFile(full, 'love2d4me');
        }
    }
    console.log('(dev) using sibling love2d4me');
} else {
    zip.addLocalFolder(gameDir);
}

zip.writeZip(out);
console.log('packed ' + out + ' (' + (fs.statSync(out).size / 1048576).toFixed(2) + ' MB)');

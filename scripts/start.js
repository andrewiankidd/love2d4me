// Launch the game using the locally-installed LOVE binary.
// Called by `npm start` or directly: node src/love2d4me/scripts/start.js
const os = require('os');
const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');

// __dirname is src/love2d4me/scripts/ — project root is three levels up
const root = path.join(__dirname, '..', '..', '..');
const loveDir = path.join(root, 'love');
const srcDir = path.join(root, 'src');

const candidates = {
  win32: [
    path.join(loveDir, 'love-11.5-win64', 'love.exe'),
    path.join(loveDir, 'love.exe'),
  ],
  linux: [
    path.join(loveDir, 'love.AppImage'),
  ],
  darwin: [
    path.join(loveDir, 'love.app', 'Contents', 'MacOS', 'love'),
    path.join(loveDir, 'love-11.5-macos', 'love.app', 'Contents', 'MacOS', 'love'),
  ],
};

const platform = os.platform();
const paths = candidates[platform] || [];
const loveBin = paths.find(p => fs.existsSync(p));

if (!loveBin) {
  console.error('LOVE binary not found. Run `npm run setup` first.');
  console.error('Searched:', paths.join(', '));
  process.exit(1);
}

console.log(`Starting: ${loveBin} ${srcDir}`);
// execFileSync bypasses shell — no extra cmd.exe/conhost windows
try {
  execFileSync(loveBin, [srcDir], { stdio: 'inherit' });
} catch (e) {
  if (e.status) process.exit(e.status);
}

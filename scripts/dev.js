// Launch the game with LOVE2D4ME_DEV pointing to the sibling love2d4me repo.
// Assumes repos are cloned side by side: ../love2d4me relative to the game root.
// Called by `npm run dev` — edits to love2d4me are picked up without push/sync.
const path = require('path');
const fs = require('fs');

// __dirname is <game>/src/love2d4me/scripts/ — game root is 3 levels up
const gameRoot = path.join(__dirname, '..', '..', '..');
const devPath = path.join(gameRoot, '..', 'love2d4me');

if (!fs.existsSync(path.join(devPath, 'init.lua'))) {
    console.error('ERROR: love2d4me repo not found at ' + devPath);
    console.error('Dev mode requires the love2d4me repo cloned as a sibling:');
    console.error('  git clone https://github.com/andrewiankidd/love2d4me.git ' + devPath);
    process.exit(1);
}

process.env.LOVE2D4ME_DEV = devPath;
require('./start.js');

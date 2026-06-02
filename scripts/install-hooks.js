// Install git hooks that run lint-vars before push.
// Called by `npm run setup` in each game repo.
const path = require('path');
const fs = require('fs');

const gameRoot = path.join(__dirname, '..', '..', '..');
const hooksDir = path.join(gameRoot, '.git', 'hooks');

if (!fs.existsSync(hooksDir)) {
  console.log('No .git/hooks directory — skipping hook install');
  process.exit(0);
}

const hook = `#!/bin/sh
# Installed by love2d4me/scripts/install-hooks.js
node src/love2d4me/scripts/lint-vars.js src
`;

const hookPath = path.join(hooksDir, 'pre-push');
fs.writeFileSync(hookPath, hook, { mode: 0o755 });
console.log('Installed pre-push hook:', hookPath);

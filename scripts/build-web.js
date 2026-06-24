// Build the web version: pack .love, run love.js, patch HTML.
// Usage: node build-web.js [project-root]
// project-root defaults to ../../../ (submodule layout).
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const root = path.resolve(process.argv[2] || path.join(__dirname, '..', '..', '..'));
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const loveName = (pkg.lovefile || pkg.name || 'game') + '.love';
const lovePath = path.join(root, loveName);

const configPath = path.join(root, 'src', 'game', 'config.json');
let title = pkg.name || 'Game';
if (fs.existsSync(configPath)) {
    const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    title = cfg.title || title;
}

const lovejs = path.join(root, 'node_modules', 'love.js', 'index.js');

const env = { ...process.env, NODE_PATH: path.join(root, 'node_modules') };

console.log('Packing .love...');
execSync(`node "${path.join(__dirname, 'pack-love.js')}"`, { cwd: root, stdio: 'inherit', env });

console.log('Running love.js...');
execSync(`node "${lovejs}" "${lovePath}" Web -t "${title}" -c`, { cwd: root, stdio: 'inherit' });

console.log('Patching HTML...');
execSync(`node "${path.join(__dirname, 'patch-web.js')}" "${root}"`, { cwd: root, stdio: 'inherit' });

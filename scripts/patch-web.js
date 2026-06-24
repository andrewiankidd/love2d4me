// Replace the love.js web build HTML with our template.
// Extracts INITIAL_MEMORY from the generated HTML and stamps it
// (along with title) into site/game.html.
// Also removes the love.js theme directory (CSS is inlined in template).
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', '..', '..');
const webDir = path.join(root, 'Web');
const indexPath = path.join(webDir, 'index.html');
const configPath = path.join(root, 'src', 'game', 'config.json');
const templatePath = path.join(__dirname, '..', 'site', 'game.html');

if (!fs.existsSync(indexPath)) {
    console.error('Web/index.html not found — run love.js build first');
    process.exit(1);
}

// Read game config for title
let title = 'Game';
if (fs.existsSync(configPath)) {
    const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    title = cfg.title || 'Game';
}

// Extract INITIAL_MEMORY from love.js generated HTML (varies per build)
const generated = fs.readFileSync(indexPath, 'utf8');
const memMatch = generated.match(/INITIAL_MEMORY:\s*(\d+)/);
const memory = memMatch ? memMatch[1] : '16777216';

// Stamp template and overwrite
let html = fs.readFileSync(templatePath, 'utf8');
html = html.replace(/\{\{title\}\}/g, title);
html = html.replace(/\{\{memory\}\}/g, memory);

fs.writeFileSync(indexPath, html);

// Remove love.js theme (CSS is inlined in our template)
const themeDir = path.join(webDir, 'theme');
if (fs.existsSync(themeDir)) {
    fs.rmSync(themeDir, { recursive: true });
}

console.log('Web build patched — ' + title);

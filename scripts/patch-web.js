// Replace the love.js-generated Web/index.html with our minimal game template.
// Run after `npm run build` to strip the default love.js chrome.
// Usage: node src/love2d4me/scripts/patch-web.js
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', '..', '..');
const webDir = path.join(root, 'Web');
const indexPath = path.join(webDir, 'index.html');
const templatePath = path.join(__dirname, '..', 'site', 'game.html');

if (!fs.existsSync(indexPath)) {
    console.error('Web/index.html not found — run npm run build first');
    process.exit(1);
}

// Extract mustache values from the generated index.html
const generated = fs.readFileSync(indexPath, 'utf8');
const argsMatch = generated.match(/arguments:\s*(\[.*?\])/s);
const memMatch = generated.match(/INITIAL_MEMORY:\s*(\d+)/);
const titleMatch = generated.match(/<title>(.*?)<\/title>/);

const args = argsMatch ? argsMatch[1] : '["./"]';
const memory = memMatch ? memMatch[1] : '83886080';
const title = titleMatch ? titleMatch[1] : 'Game';

// Render template
let template = fs.readFileSync(templatePath, 'utf8');
template = template.replace('{{{arguments}}}', args);
template = template.replace('{{memory}}', memory);
template = template.replace(/\{\{title\}\}/g, title);

fs.writeFileSync(indexPath, template);

// Remove the love.js theme folder (the pink/blue CSS)
const themeDir = path.join(webDir, 'theme');
if (fs.existsSync(themeDir)) {
    fs.rmSync(themeDir, { recursive: true });
}

console.log('Web/index.html patched — minimal game template applied');

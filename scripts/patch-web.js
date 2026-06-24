// Replace the love.js web build HTML with our template.
// Reads game resolution from config.json and INITIAL_MEMORY from the
// generated index.html, stamps them into site/game.html, overwrites.
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

// Read game config
let gameW = 800, gameH = 600, title = 'Game';
let cfg = {};
if (fs.existsSync(configPath)) {
    cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    gameW = cfg.width || 800;
    gameH = cfg.height || 600;
    title = cfg.title || 'Game';
}

// If a skin is configured, the canvas must be large enough for the skin's
// window dimensions (the skin calls love.window.setMode at its own size).
const skinName = (cfg.platform_skins && cfg.platform_skins.desktop) || cfg.default_skin;
if (skinName && skinName !== 'none') {
    const skinSearchPaths = [
        path.join(root, 'skins', skinName, 'skin.json'),
        path.join(root, 'src', 'love2d4me', 'skins', skinName, 'skin.json'),
    ];
    for (const sp of skinSearchPaths) {
        if (fs.existsSync(sp)) {
            const skin = JSON.parse(fs.readFileSync(sp, 'utf8'));
            if (skin.width)  gameW = Math.max(gameW, skin.width);
            if (skin.height) gameH = Math.max(gameH, skin.height);
            console.log('Skin "' + skinName + '" detected — canvas expanded to ' + gameW + 'x' + gameH);
            break;
        }
    }
}

// Extract INITIAL_MEMORY from love.js generated HTML (varies per build)
const generated = fs.readFileSync(indexPath, 'utf8');
const memMatch = generated.match(/INITIAL_MEMORY:\s*(\d+)/);
const memory = memMatch ? memMatch[1] : '16777216';

// Stamp template and overwrite
let html = fs.readFileSync(templatePath, 'utf8');
html = html.replace(/\{\{title\}\}/g, title);
html = html.replace(/\{\{width\}\}/g, String(gameW));
html = html.replace(/\{\{height\}\}/g, String(gameH));
html = html.replace(/\{\{memory\}\}/g, memory);

fs.writeFileSync(indexPath, html);

// Remove love.js theme (CSS is inlined in our template)
const themeDir = path.join(webDir, 'theme');
if (fs.existsSync(themeDir)) {
    fs.rmSync(themeDir, { recursive: true });
}

console.log('Web build patched (' + gameW + 'x' + gameH + ')');

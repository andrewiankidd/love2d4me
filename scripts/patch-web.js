// Patch the love.js web build: lock canvas to game resolution, clean theme,
// CSS-scale to fill viewport.
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', '..', '..');
const webDir = path.join(root, 'Web');
const indexPath = path.join(webDir, 'index.html');
const cssPath = path.join(webDir, 'theme', 'love.css');
const configPath = path.join(root, 'src', 'game', 'config.json');

if (!fs.existsSync(indexPath)) {
    console.error('Web/index.html not found — run npm run build first');
    process.exit(1);
}

let gameW = 800, gameH = 600;
if (fs.existsSync(configPath)) {
    const cfg = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    gameW = cfg.width || 800;
    gameH = cfg.height || 600;
}

if (fs.existsSync(cssPath)) {
    fs.writeFileSync(cssPath, `* { box-sizing: border-box; }
body { margin: 0; overflow: hidden; background: #000; }
h1, footer { display: none; }
#canvas { display: block; border: 0; padding: 0; visibility: hidden; }
`);
}

let html = fs.readFileSync(indexPath, 'utf8');

html = html.replace(
    /function FullScreenHook\(\)\{[^}]+\}/,
    'function FullScreenHook(){}'
);

// Set canvas attributes in the HTML tag itself
html = html.replace(
    '<canvas id="canvas" oncontextmenu="event.preventDefault()"></canvas>',
    '<canvas id="canvas" oncontextmenu="event.preventDefault()" width="' + gameW + '" height="' + gameH + '"></canvas>'
);

// Lock DPR and canvas dimensions before love.js can touch them
const EARLY_INJECT = `
    <script>
    Object.defineProperty(window, 'devicePixelRatio', {value: 1, writable: false});
    (function() {
        var c = document.getElementById('canvas');
        Object.defineProperty(c, 'width', {
            get: function() { return ${gameW}; },
            set: function() {},
            configurable: true
        });
        Object.defineProperty(c, 'height', {
            get: function() { return ${gameH}; },
            set: function() {},
            configurable: true
        });
    })();
    </script>
`;
html = html.replace('<script type=\'text/javascript\'>', EARLY_INJECT + '    <script type=\'text/javascript\'>');

const LATE_INJECT = `
<script>
(function() {
    function fitCanvas() {
        var c = document.getElementById('canvas');
        if (!c || c.style.visibility === 'hidden') return;
        var sx = window.innerWidth / ${gameW};
        var sy = window.innerHeight / ${gameH};
        var s = Math.min(sx, sy);
        c.style.position = 'fixed';
        c.style.transformOrigin = '0 0';
        c.style.transform = 'scale(' + s + ')';
        c.style.left = Math.round((window.innerWidth - ${gameW} * s) / 2) + 'px';
        c.style.top = Math.round((window.innerHeight - ${gameH} * s) / 2) + 'px';
    }
    window.addEventListener('resize', fitCanvas);
    setInterval(fitCanvas, 200);
})();
</script>
`;
html = html.replace('</body>', LATE_INJECT + '</body>');

fs.writeFileSync(indexPath, html);
console.log('Web build patched (' + gameW + 'x' + gameH + ' locked + theme + scaling)');

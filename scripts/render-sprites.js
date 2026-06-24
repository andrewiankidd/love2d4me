#!/usr/bin/env node
// render-sprites.js -- Render a 3D model into a sprite sheet.
//
// Reads a sprites.json config, starts a local HTTP server, opens the
// system browser to render each pose via three.js WebGL, and saves the
// resulting sprite sheet PNG + frame map JSON.
//
// Usage:
//   node src/love2d4me/scripts/render-sprites.js src/game/sprites.json
//
// Zero heavy dependencies — three.js loads from CDN in the browser.

const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const configPath = process.argv[2];
if (!configPath) {
    console.error('Usage: node render-sprites.js <sprites.json>');
    process.exit(1);
}

const configAbs = path.resolve(configPath);
const configDir = path.dirname(configAbs);
const config = JSON.parse(fs.readFileSync(configAbs, 'utf8'));

if (!config.model) {
    console.error('Config must specify "model" path');
    process.exit(1);
}
if (!config.poses || !config.poses.length) {
    console.error('Config must specify at least one pose');
    process.exit(1);
}

const PORT = 9473;
const rendererHtml = fs.readFileSync(
    path.join(__dirname, 'sprite-renderer.html'), 'utf8'
);

console.log(`Model: ${config.model}`);
console.log(`Poses: ${config.poses.map(p => p.name).join(', ')}`);
console.log(`Frame size: ${config.frame_size || 128}px`);

const server = http.createServer((req, res) => {
    // CORS headers for local dev
    res.setHeader('Access-Control-Allow-Origin', '*');

    if (req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(rendererHtml);
        return;
    }

    if (req.url === '/config') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(config));
        return;
    }

    // Serve model and any related files (textures, bin) from config dir
    if (req.url.startsWith('/assets/')) {
        const rel = decodeURIComponent(req.url.slice(8));
        const filePath = path.resolve(configDir, rel);
        // Security: don't escape config directory
        if (!filePath.startsWith(configDir)) {
            res.writeHead(403);
            res.end('Forbidden');
            return;
        }
        if (fs.existsSync(filePath)) {
            const ext = path.extname(filePath).toLowerCase();
            const mimeTypes = {
                '.glb': 'model/gltf-binary',
                '.gltf': 'model/gltf+json',
                '.bin': 'application/octet-stream',
                '.png': 'image/png',
                '.jpg': 'image/jpeg',
                '.jpeg': 'image/jpeg',
            };
            res.writeHead(200, {
                'Content-Type': mimeTypes[ext] || 'application/octet-stream'
            });
            res.end(fs.readFileSync(filePath));
        } else {
            res.writeHead(404);
            res.end('Not found: ' + rel);
        }
        return;
    }

    if (req.url === '/save' && req.method === 'POST') {
        const chunks = [];
        req.on('data', chunk => chunks.push(chunk));
        req.on('end', () => {
            try {
                const data = JSON.parse(Buffer.concat(chunks).toString());

                // Save sprite sheet PNG
                const outputPath = path.resolve(configDir, config.output || 'sprites.png');
                const outputDir = path.dirname(outputPath);
                fs.mkdirSync(outputDir, { recursive: true });

                const pngData = Buffer.from(data.sheet.split(',')[1], 'base64');
                fs.writeFileSync(outputPath, pngData);
                console.log(`Sprite sheet saved: ${outputPath}`);

                // Save frame map JSON
                const mapPath = outputPath.replace(/\.png$/i, '.json');
                fs.writeFileSync(mapPath, JSON.stringify(data.map, null, 2));
                console.log(`Frame map saved: ${mapPath}`);

                res.writeHead(200, { 'Content-Type': 'text/plain' });
                res.end('OK');

                // Done — shut down after a brief delay for the response to flush
                setTimeout(() => {
                    server.close();
                    process.exit(0);
                }, 500);
            } catch (err) {
                console.error('Save error:', err);
                res.writeHead(500);
                res.end('Error: ' + err.message);
            }
        });
        return;
    }

    res.writeHead(404);
    res.end('Not found');
});

server.listen(PORT, () => {
    const url = `http://localhost:${PORT}`;
    console.log(`Renderer running at ${url}`);
    console.log('Opening browser...');

    // Open system browser
    const platform = process.platform;
    const cmd = platform === 'win32' ? `start "" "${url}"`
        : platform === 'darwin' ? `open "${url}"`
        : `xdg-open "${url}"`;
    exec(cmd, (err) => {
        if (err) console.error('Could not open browser:', err.message);
    });
});

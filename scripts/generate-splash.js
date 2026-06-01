// Generate a splash sprite sheet from the andrewkidd logo SVG.
// Renders frames: fade in, spin with deceleration, settle, punk reveal, fade out.
// Output: assets/splash.png (sprite sheet, 280x280 per frame)

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Check for canvas dependency
try { require('canvas'); } catch (e) {
    console.log('Installing canvas dependency...');
    execSync('npm install canvas --no-save', { cwd: path.join(__dirname, '..'), stdio: 'inherit' });
}

const { createCanvas } = require('canvas');

const FW = 280, FH = 280;
const FPS = 20;
const FADE_IN = 0.6;
const SPIN_START = 0.0;
const SPIN_END = 2.0;
const SPIN_REVS = 3;
const PUNK_AT = 2.4;
const FADE_OUT = 3.2;
const TOTAL = 3.8;

const FRAMES = Math.ceil(TOTAL * FPS);
const COLS = 10;
const ROWS = Math.ceil(FRAMES / COLS);

function easeOutQuad(t) { return 1 - (1 - t) * (1 - t); }

// Logo geometry (viewBox 0 0 200 200)
const LOGO = {
    cx: 100, cy: 100, r: 90,
    circleW: 8, lineW: 6.4,
    lines: [
        [163.6, 36.4, 36.4, 163.6],
        [36.4, 163.6, 100, 10],
        [100, 100, 163.6, 163.6],
        [100, 10, 100, 190],
    ],
    punk: [
        [163.6, 36.4, 177.7, 22.3],
        [36.4, 163.6, 22.3, 177.7],
        [36.4, 163.6, 28.7, 182.1],
        [100, 10, 107.7, -8.5],
        [163.6, 163.6, 177.7, 177.7],
        [100, 10, 100, -10],
        [100, 190, 100, 210],
    ],
};

function renderFrame(ctx, t) {
    ctx.clearRect(0, 0, FW, FH);
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, FW, FH);

    // Alpha
    let alpha = 0;
    if (t < FADE_IN) alpha = t / FADE_IN;
    else if (t < FADE_OUT) alpha = 1;
    else alpha = 1 - Math.min((t - FADE_OUT) / (TOTAL - FADE_OUT), 1);

    // Rotation
    let rotation = 0;
    if (t >= SPIN_START && t < SPIN_END) {
        const p = (t - SPIN_START) / (SPIN_END - SPIN_START);
        rotation = easeOutQuad(p) * SPIN_REVS * Math.PI * 2;
    } else if (t >= SPIN_END) {
        rotation = SPIN_REVS * Math.PI * 2;
    }

    const showPunk = t >= PUNK_AT;
    const scale = FW * 0.35 / 100;

    ctx.save();
    ctx.translate(FW / 2, FH / 2);
    ctx.rotate(rotation);
    ctx.scale(scale, scale);
    ctx.translate(-LOGO.cx, -LOGO.cy);

    ctx.strokeStyle = `rgba(255,255,255,${alpha})`;
    ctx.lineCap = 'round';

    // Circle
    ctx.lineWidth = LOGO.circleW;
    ctx.beginPath();
    ctx.arc(LOGO.cx, LOGO.cy, LOGO.r, 0, Math.PI * 2);
    ctx.stroke();

    // Base lines
    ctx.lineWidth = LOGO.lineW;
    for (const l of LOGO.lines) {
        ctx.beginPath();
        ctx.moveTo(l[0], l[1]);
        ctx.lineTo(l[2], l[3]);
        ctx.stroke();
    }

    // Punk
    if (showPunk) {
        const punkAlpha = Math.min((t - PUNK_AT) / 0.15, 1) * alpha;
        ctx.strokeStyle = `rgba(255,255,255,${punkAlpha})`;
        for (const l of LOGO.punk) {
            ctx.beginPath();
            ctx.moveTo(l[0], l[1]);
            ctx.lineTo(l[2], l[3]);
            ctx.stroke();
        }
    }

    ctx.restore();
}

// Render all frames
const sheet = createCanvas(COLS * FW, ROWS * FH);
const sheetCtx = sheet.getContext('2d');
sheetCtx.fillStyle = '#000';
sheetCtx.fillRect(0, 0, sheet.width, sheet.height);

const frame = createCanvas(FW, FH);
const frameCtx = frame.getContext('2d');

for (let i = 0; i < FRAMES; i++) {
    const t = (i / FPS);
    renderFrame(frameCtx, t);
    const col = i % COLS;
    const row = Math.floor(i / COLS);
    sheetCtx.drawImage(frame, col * FW, row * FH);
}

const out = path.join(__dirname, '..', 'assets', 'splash.png');
fs.writeFileSync(out, sheet.toBuffer('image/png'));
console.log(`Generated ${FRAMES} frames (${COLS}x${ROWS}) -> ${out} (${(fs.statSync(out).size / 1024).toFixed(0)} KB)`);

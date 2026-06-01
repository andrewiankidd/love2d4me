// Download and extract LOVE 11.5 for the current platform.
// Called by `npm run setup` to bootstrap a dev machine.
const os = require('os');
const path = require('path');
const fs = require('fs');
const https = require('https');
const { execSync } = require('child_process');

const LOVE_VERSION = '11.5';
// __dirname is src/love2d4me/scripts/ — project root is three levels up
const ROOT = path.join(__dirname, '..', '..', '..');
const DEST = path.join(ROOT, 'love');

const URLS = {
  win32:  `https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-win64.zip`,
  linux:  `https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-linux-x86_64.AppImage`,
  darwin: `https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-macos.zip`,
};

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const follow = (url) => {
      https.get(url, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          follow(res.headers.location);
          return;
        }
        if (res.statusCode !== 200) {
          reject(new Error(`HTTP ${res.statusCode} for ${url}`));
          return;
        }
        const file = fs.createWriteStream(dest);
        res.pipe(file);
        file.on('finish', () => { file.close(); resolve(); });
      }).on('error', reject);
    };
    follow(url);
  });
}

async function main() {
  const platform = os.platform();
  const url = URLS[platform];
  if (!url) {
    console.error(`No LOVE download configured for platform: ${platform}`);
    console.error('Install LOVE 11.x manually from https://love2d.org');
    process.exit(1);
  }

  if (fs.existsSync(DEST)) {
    console.log(`LOVE already exists at ${DEST} — skipping download`);
    return;
  }

  const filename = path.basename(url);
  const tmpFile = path.join(os.tmpdir(), filename);
  console.log(`Downloading LOVE ${LOVE_VERSION} for ${platform}...`);
  await download(url, tmpFile);

  fs.mkdirSync(DEST, { recursive: true });

  if (filename.endsWith('.zip')) {
    console.log('Extracting...');
    if (platform === 'win32') {
      execSync(`powershell -Command "Expand-Archive -Path '${tmpFile}' -DestinationPath '${DEST}' -Force"`);
    } else {
      execSync(`unzip -qo '${tmpFile}' -d '${DEST}'`);
    }
  } else if (filename.endsWith('.AppImage')) {
    const appImage = path.join(DEST, 'love.AppImage');
    fs.copyFileSync(tmpFile, appImage);
    fs.chmodSync(appImage, 0o755);
    console.log(`AppImage saved to ${appImage}`);
  }

  fs.unlinkSync(tmpFile);
  console.log(`LOVE ${LOVE_VERSION} installed to ${DEST}`);
}

main().catch((err) => { console.error(err); process.exit(1); });

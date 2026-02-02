const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

const FRAMES_DIR = path.join(__dirname, 'frames');
const OUTPUT_GIF = path.join(__dirname, 'demo.gif');
const OUTPUT_MP4 = path.join(__dirname, 'demo.mp4');
const DEMO_HTML = path.join(__dirname, 'demo-video.html');

// Demo duration in milliseconds
const DEMO_DURATION = 12000;
const FRAME_RATE = 15;
const FRAME_INTERVAL = 1000 / FRAME_RATE;

async function recordDemo() {
  console.log('🎬 デモ録画を開始...');

  // Create frames directory
  if (fs.existsSync(FRAMES_DIR)) {
    fs.rmSync(FRAMES_DIR, { recursive: true });
  }
  fs.mkdirSync(FRAMES_DIR);

  // Launch browser
  const browser = await puppeteer.launch({
    headless: false,
    defaultViewport: { width: 800, height: 600 },
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    args: ['--window-size=800,600', '--no-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 800, height: 600 });

  // Load demo page
  console.log('📄 デモページを読み込み中...');
  await page.goto(`file://${DEMO_HTML}`);
  await page.waitForSelector('#terminal');

  // Wait a moment for page to render
  await sleep(500);

  // Start the demo by clicking the start button
  console.log('▶️  デモを開始...');
  await page.evaluate(() => {
    // Hide controls
    document.getElementById('controls').style.display = 'none';
    // Start demo
    startDemo();
  });

  // Capture frames
  console.log(`📸 フレームをキャプチャ中 (${FRAME_RATE}fps, ${DEMO_DURATION / 1000}秒)...`);

  const startTime = Date.now();
  let frameCount = 0;

  while (Date.now() - startTime < DEMO_DURATION) {
    const frameNumber = String(frameCount).padStart(4, '0');
    const framePath = path.join(FRAMES_DIR, `frame_${frameNumber}.png`);

    await page.screenshot({ path: framePath });
    frameCount++;

    // Wait for next frame
    const elapsed = Date.now() - startTime;
    const nextFrameTime = frameCount * FRAME_INTERVAL;
    const waitTime = Math.max(0, nextFrameTime - elapsed);

    if (waitTime > 0) {
      await sleep(waitTime);
    }
  }

  console.log(`✅ ${frameCount}フレームをキャプチャしました`);

  await browser.close();

  // Convert frames to GIF using ffmpeg
  console.log('🔄 GIFに変換中...');
  try {
    execSync(
      `ffmpeg -y -framerate ${FRAME_RATE} -i "${FRAMES_DIR}/frame_%04d.png" ` +
      `-vf "scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" ` +
      `-loop 0 "${OUTPUT_GIF}"`,
      { stdio: 'inherit' }
    );
    console.log(`✅ GIF作成完了: ${OUTPUT_GIF}`);
  } catch (e) {
    console.error('GIF変換エラー:', e.message);
  }

  // Also create MP4
  console.log('🔄 MP4に変換中...');
  try {
    execSync(
      `ffmpeg -y -framerate ${FRAME_RATE} -i "${FRAMES_DIR}/frame_%04d.png" ` +
      `-c:v libx264 -pix_fmt yuv420p -crf 23 "${OUTPUT_MP4}"`,
      { stdio: 'inherit' }
    );
    console.log(`✅ MP4作成完了: ${OUTPUT_MP4}`);
  } catch (e) {
    console.error('MP4変換エラー:', e.message);
  }

  // Cleanup frames
  console.log('🧹 一時ファイルを削除中...');
  fs.rmSync(FRAMES_DIR, { recursive: true });

  console.log('\n🎉 録画完了!');
  console.log(`   GIF: ${OUTPUT_GIF}`);
  console.log(`   MP4: ${OUTPUT_MP4}`);

  // Show file sizes
  if (fs.existsSync(OUTPUT_GIF)) {
    const gifSize = (fs.statSync(OUTPUT_GIF).size / 1024 / 1024).toFixed(2);
    console.log(`   GIFサイズ: ${gifSize} MB`);
  }
  if (fs.existsSync(OUTPUT_MP4)) {
    const mp4Size = (fs.statSync(OUTPUT_MP4).size / 1024 / 1024).toFixed(2);
    console.log(`   MP4サイズ: ${mp4Size} MB`);
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

recordDemo().catch(console.error);

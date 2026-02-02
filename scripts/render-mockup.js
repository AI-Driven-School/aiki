#!/usr/bin/env node
/**
 * HTML/React → PNG モックアップレンダラー
 *
 * 使用方法:
 *   node render-mockup.js <html-file> <output-png> [width] [height]
 *   node render-mockup.js mockup.html mockups/login.png 390 844
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function renderMockup(htmlPath, outputPath, width = 390, height = 844) {
    // HTML読み込み
    let html;
    if (htmlPath === '-') {
        // stdinから読み込み
        html = fs.readFileSync(0, 'utf-8');
    } else {
        html = fs.readFileSync(htmlPath, 'utf-8');
    }

    // 出力ディレクトリ作成
    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    // Tailwind CDN追加（なければ）
    if (!html.includes('tailwindcss')) {
        html = html.replace('<head>', `<head>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: '#6366f1',
                        secondary: '#8b5cf6',
                    }
                }
            }
        }
    </script>`);
    }

    // フォント追加
    if (!html.includes('fonts.googleapis')) {
        html = html.replace('<head>', `<head>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Noto+Sans+JP:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        * { font-family: 'Inter', 'Noto Sans JP', sans-serif; }
        body { margin: 0; padding: 0; }
    </style>`);
    }

    // ブラウザ起動
    const browser = await chromium.launch();
    const page = await browser.newPage({
        viewport: { width: parseInt(width), height: parseInt(height) },
        deviceScaleFactor: 2, // Retina品質
    });

    // HTMLをレンダリング
    await page.setContent(html, { waitUntil: 'networkidle' });

    // 少し待機（フォント読み込み）
    await page.waitForTimeout(500);

    // スクリーンショット
    await page.screenshot({
        path: outputPath,
        type: 'png',
    });

    await browser.close();

    console.log(`✅ ${outputPath} を作成しました (${width}x${height})`);
    return outputPath;
}

// デバイスプリセット
const devices = {
    'iphone': { width: 390, height: 844 },
    'iphone-se': { width: 375, height: 667 },
    'ipad': { width: 820, height: 1180 },
    'desktop': { width: 1440, height: 900 },
    'macbook': { width: 1512, height: 982 },
};

// CLI実行
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.length < 2) {
        console.log(`
📱 モックアップレンダラー

使用方法:
  node render-mockup.js <html-file> <output-png> [width] [height]
  node render-mockup.js <html-file> <output-png> [device]

デバイスプリセット:
  iphone    : 390x844
  iphone-se : 375x667
  ipad      : 820x1180
  desktop   : 1440x900
  macbook   : 1512x982

例:
  node render-mockup.js login.html mockups/login.png iphone
  node render-mockup.js dashboard.html mockups/dashboard.png desktop
  echo "<html>..." | node render-mockup.js - mockups/test.png
        `);
        process.exit(1);
    }

    const [htmlPath, outputPath, sizeOrDevice, height] = args;

    let w, h;
    if (devices[sizeOrDevice]) {
        w = devices[sizeOrDevice].width;
        h = devices[sizeOrDevice].height;
    } else {
        w = sizeOrDevice || 390;
        h = height || 844;
    }

    renderMockup(htmlPath, outputPath, w, h).catch(err => {
        console.error('❌ エラー:', err.message);
        process.exit(1);
    });
}

module.exports = { renderMockup, devices };

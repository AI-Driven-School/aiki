# デモ動画の録画手順

## 1. 録画用ページを開く

```bash
open landing/demo-video.html
```

## 2. 録画方法

### Mac の場合
1. `Cmd + Shift + 5` でスクリーン録画を開始
2. 録画範囲をブラウザウィンドウに合わせる
3. 「録画モード」ボタンをクリック（コントロールが非表示になる）
4. 自動でデモが開始される
5. 終了したら `Cmd + Control + Esc` で録画停止

### Windows の場合
1. `Windows + G` でゲームバーを開く
2. 録画開始
3. 「録画モード」ボタンをクリック
4. デモ終了後に録画停止

## 3. GIF に変換

### ffmpeg を使用（推奨）

```bash
# 動画をGIFに変換（高品質）
ffmpeg -i demo.mov -vf "fps=15,scale=800:-1:flags=lanczos" -c:v gif demo.gif

# ファイルサイズを小さくする場合
ffmpeg -i demo.mov -vf "fps=10,scale=600:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" demo.gif
```

### Gifski を使用（最高品質）

```bash
brew install gifski
gifski --fps 15 --width 800 -o demo.gif demo.mov
```

## 4. ファイル配置

```
landing/
├── demo.gif          # README用
├── demo.mp4          # Twitter/X用
└── demo-video.html   # 録画用ページ
```

## 5. README に追加

```markdown
## デモ

![3AI協調開発デモ](./landing/demo.gif)
```

## Tips

- **録画サイズ**: 800x600px が最適
- **GIFファイルサイズ**: 5MB以下を目安に
- **SNS用MP4**: 30秒以内、16:9 または 1:1

## 自動録画（Puppeteer）

```bash
# 必要なパッケージ
npm install puppeteer puppeteer-screen-recorder

# 録画スクリプト実行
node landing/record-demo.js
```

---

## ランディングページのプレビュー

```bash
# ローカルサーバーで確認
npx serve landing

# または
python -m http.server 8000 -d landing
```

http://localhost:8000 でアクセス

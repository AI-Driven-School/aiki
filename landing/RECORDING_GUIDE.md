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

![4AI協調開発デモ](./landing/demo.gif)
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

## Viral Demo - リアルターミナル録画（推奨）

本物のターミナルで動くシミュレーションを asciinema で録画する方式。
Reddit / X で最も信頼されるフォーマット。

### 必要なツール

```bash
brew install asciinema agg ffmpeg
```

| ツール | 用途 |
|--------|------|
| asciinema | ターミナル録画 (.cast) |
| agg | .cast → GIF 変換 |
| ffmpeg | GIF → MP4 変換 |

### ワンコマンド録画

```bash
# 全自動: 録画 → GIF → MP4
bash landing/record-real.sh
```

### 手動ステップ

```bash
# 1. プレビュー（録画せずに確認）
bash landing/simulate-demo.sh

# 2. asciinema で録画
asciinema rec --cols 80 --rows 24 \
  --command "bash landing/simulate-demo.sh" \
  landing/viral-demo.cast

# 3. GIF に変換
agg --font-size 16 --fps-cap 15 \
  landing/viral-demo.cast landing/viral-demo.gif

# 4. MP4 に変換
ffmpeg -y -i landing/viral-demo.gif \
  -pix_fmt yuv420p -c:v libx264 -crf 20 \
  landing/viral-demo.mp4
```

### 出力ファイル

| ファイル | 用途 | 目標サイズ |
|---------|------|-----------|
| `landing/viral-demo.cast` | asciinema 再生用 | - |
| `landing/viral-demo.gif` | README / GitHub | < 10MB |
| `landing/viral-demo.mp4` | X/Twitter, Reddit | < 5MB |

### デモ構成（約35秒）

1. `npx aiki init my-app` - セットアップ
2. `/project user authentication` - 6フェーズ実行
   - Requirements (Claude) → API Design (Claude) → Implementation (Codex, $0)
   - Testing (Codex, $0) → Review (Claude) → Deploy
3. 完了サマリー（時間・コスト・ファイル数）
4. コスト比較バー（Single AI $0.85 vs 4-AI $0.21）

### SNS 投稿のコツ

- **Reddit**: テキスト投稿 + GIF埋め込み。リンクだけの投稿はダウンボートされやすい
- **X/Twitter**: MP4 をネイティブ投稿（リンクではなくメディアとして添付）
- **タイトル例**: "Built auth in 3 min using Claude + Codex. Here's what happened."
- **投稿時間**: 火〜木 9-11am PST が最適

---

## Viral Demo - HTML アニメーション版（代替）

ブラウザベースの HTML アニメーションデモ（英語）。
README 用 GIF として使える。Puppeteer + ffmpeg で録画。

### 使い方

```bash
# ブラウザでプレビュー
open landing/demo-viral.html

# Space で開始、Record Mode でコントロール非表示 + 自動開始
```

### 自動録画

```bash
npm install puppeteer
node landing/record-viral.js
```

| 設定 | 値 |
|------|-----|
| 解像度 | 1280x720 (HD 16:9) |
| 長さ | 約45秒 |
| フレームレート | 30fps（録画）/ 15fps（GIF） |

---

## ランディングページのプレビュー

```bash
# ローカルサーバーで確認
npx serve landing

# または
python -m http.server 8000 -d landing
```

http://localhost:8000 でアクセス

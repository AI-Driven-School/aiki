---
name: mockup
description: UIモックアップをPNG画像として生成
---

# /mockup スキル

UIモックアップをHTML/Tailwind CSSで生成し、PNG画像としてレンダリングします。

## 使用方法

```
/mockup ログイン画面
/mockup ダッシュボード画面 --device desktop
/mockup 商品詳細ページ --device ipad
```

## 実行フロー

1. **HTML生成**: Tailwind CSSを使用したモックアップHTMLを生成
2. **PNG変換**: Playwrightでレンダリングしてスクリーンショット
3. **保存**: `mockups/` ディレクトリに保存

## デバイスプリセット

| デバイス | サイズ | 用途 |
|---------|--------|------|
| `iphone` | 390x844 | モバイルアプリ（デフォルト） |
| `iphone-se` | 375x667 | 小型モバイル |
| `ipad` | 820x1180 | タブレット |
| `desktop` | 1440x900 | デスクトップWeb |
| `macbook` | 1512x982 | MacBook |

## 実装手順

### Step 1: HTMLファイル生成

```html
<!-- mockups/temp-{name}.html -->
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50">
    <!-- UIコンポーネントをここに生成 -->
</body>
</html>
```

### Step 2: PNG変換

```bash
node scripts/render-mockup.js mockups/temp-{name}.html mockups/{name}.png iphone
```

### Step 3: 設計書に追加

生成した画像パスを設計書やドキュメントに記載。

## デザインガイドライン

### カラーパレット

```html
<!-- Primary -->
<div class="bg-indigo-500 text-white">プライマリ</div>

<!-- Secondary -->
<div class="bg-violet-500 text-white">セカンダリ</div>

<!-- Success -->
<div class="bg-emerald-500 text-white">成功</div>

<!-- Warning -->
<div class="bg-amber-500 text-white">警告</div>

<!-- Danger -->
<div class="bg-rose-500 text-white">エラー</div>
```

### コンポーネントパターン

#### ボタン
```html
<button class="px-6 py-3 bg-indigo-500 text-white font-medium rounded-xl hover:bg-indigo-600 transition-colors">
    ボタン
</button>
```

#### カード
```html
<div class="bg-white rounded-2xl shadow-lg p-6">
    <h3 class="text-lg font-bold text-gray-900">タイトル</h3>
    <p class="text-gray-600 mt-2">説明テキスト</p>
</div>
```

#### 入力フィールド
```html
<input type="text"
    class="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none"
    placeholder="入力してください">
```

#### ナビゲーションバー
```html
<nav class="fixed top-0 left-0 right-0 bg-white/80 backdrop-blur-lg border-b border-gray-100 px-4 py-3">
    <div class="flex items-center justify-between max-w-lg mx-auto">
        <h1 class="text-lg font-bold text-gray-900">アプリ名</h1>
        <button class="p-2">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
            </svg>
        </button>
    </div>
</nav>
```

#### タブバー（モバイル）
```html
<nav class="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 px-4 py-2 pb-8">
    <div class="flex justify-around items-center">
        <button class="flex flex-col items-center text-indigo-500">
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
            </svg>
            <span class="text-xs mt-1">ホーム</span>
        </button>
        <button class="flex flex-col items-center text-gray-400">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
            </svg>
            <span class="text-xs mt-1">マイページ</span>
        </button>
    </div>
</nav>
```

## 出力例

```
> /mockup ログイン画面

📱 モックアップ生成中...

[1/3] HTML生成中...
[2/3] Playwrightでレンダリング中...
[3/3] PNG保存中...

✅ mockups/login.png を作成しました (390x844)

📎 設計書に追加:
![ログイン画面](./mockups/login.png)
```

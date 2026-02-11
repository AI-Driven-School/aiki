---
name: frontend-design
description: AI臭くない、プロダクション品質のフロントエンドデザイン生成
---

# /frontend-design スキル

独自性のある、AI臭くないフロントエンドUIを生成します。

## 使用方法

```
/frontend-design ログインフォーム
/frontend-design ダッシュボード --style minimal
/frontend-design 商品カード --style bold
```

## AI臭いデザインを避ける原則

### ❌ 避けるべきパターン

1. **グラデーション乱用**
   - 紫→青→ピンクの派手なグラデーション
   - 背景全体にグラデーション

2. **過剰な装飾**
   - 無意味なアイコン配置
   - 過剰なシャドウとボーダー
   - ネオン風のグロー効果

3. **テンプレート感**
   - Hero + 3カラム + CTA の定型レイアウト
   - 「Welcome to...」「Get Started」などの定型文
   - ストックフォト風のイラスト配置

4. **一貫性のなさ**
   - 余白のバラつき
   - フォントサイズの乱用
   - カラーの統一感なし

### ✅ 採用すべきアプローチ

1. **制約のあるカラーパレット**
   - 最大3色（プライマリ、アクセント、グレースケール）
   - 彩度を抑えた落ち着いた色使い

2. **意図的な余白**
   - 8px グリッドシステム
   - コンテンツに呼吸を持たせる

3. **タイポグラフィの階層**
   - 明確なサイズ階層（3-4段階）
   - ウェイトのコントラスト

4. **機能的な装飾のみ**
   - 意味のあるアイコン
   - 状態を示すシャドウ

---

## デザインスタイル

### Minimal（ミニマル）
```
特徴: 余白重視、モノトーン基調、細いボーダー
用途: SaaS、ダッシュボード、管理画面
```

### Bold（ボールド）
```
特徴: 大きなタイポグラフィ、コントラスト強め、ダークモード
用途: LP、ポートフォリオ、メディアサイト
```

### Soft（ソフト）
```
特徴: 丸み、パステル調、アニメーション控えめ
用途: ヘルスケア、教育、子供向け
```

### Corporate（コーポレート）
```
特徴: 信頼感、整列、控えめなアクセント
用途: 企業サイト、B2B、金融
```

---

## カラーシステム

### Minimal パレット
```css
--bg: #fafafa;
--surface: #ffffff;
--text-primary: #18181b;
--text-secondary: #71717a;
--border: #e4e4e7;
--accent: #18181b;
```

### Bold パレット
```css
--bg: #09090b;
--surface: #18181b;
--text-primary: #fafafa;
--text-secondary: #a1a1aa;
--border: #27272a;
--accent: #fafafa;
```

### Soft パレット
```css
--bg: #fef7f0;
--surface: #ffffff;
--text-primary: #44403c;
--text-secondary: #78716c;
--border: #f5f5f4;
--accent: #ea580c;
```

---

## コンポーネントライブラリ

### ボタン

```html
<!-- Primary -->
<button class="px-4 py-2.5 bg-zinc-900 text-white text-sm font-medium rounded-lg hover:bg-zinc-800 transition-colors">
    続ける
</button>

<!-- Secondary -->
<button class="px-4 py-2.5 bg-white text-zinc-900 text-sm font-medium rounded-lg border border-zinc-200 hover:bg-zinc-50 transition-colors">
    キャンセル
</button>

<!-- Ghost -->
<button class="px-4 py-2.5 text-zinc-600 text-sm font-medium rounded-lg hover:bg-zinc-100 transition-colors">
    詳細を見る
</button>
```

### 入力フィールド

```html
<div class="space-y-1.5">
    <label class="block text-sm font-medium text-zinc-700">メールアドレス</label>
    <input type="email"
        class="w-full px-3.5 py-2.5 text-sm bg-white border border-zinc-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-zinc-900 focus:ring-offset-1 placeholder:text-zinc-400"
        placeholder="you@example.com">
</div>
```

### カード

```html
<div class="bg-white rounded-xl border border-zinc-200 p-5">
    <div class="flex items-start justify-between">
        <div>
            <h3 class="text-sm font-semibold text-zinc-900">プロジェクト名</h3>
            <p class="text-sm text-zinc-500 mt-0.5">最終更新: 2時間前</p>
        </div>
        <span class="px-2 py-1 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-md">
            アクティブ
        </span>
    </div>
</div>
```

### ナビゲーション

```html
<nav class="flex items-center justify-between px-6 py-4 border-b border-zinc-100">
    <div class="flex items-center gap-8">
        <span class="text-lg font-semibold text-zinc-900">ロゴ</span>
        <div class="flex items-center gap-6">
            <a href="#" class="text-sm font-medium text-zinc-900">ホーム</a>
            <a href="#" class="text-sm text-zinc-500 hover:text-zinc-900">機能</a>
            <a href="#" class="text-sm text-zinc-500 hover:text-zinc-900">料金</a>
        </div>
    </div>
    <button class="px-4 py-2 text-sm font-medium text-white bg-zinc-900 rounded-lg">
        始める
    </button>
</nav>
```

---

## モックアップ連携

`/frontend-design` で生成したコードは `/mockup` でPNG化できます。

```
> /frontend-design ログイン画面 --style minimal

[HTMLコード生成]

> /mockup ログイン画面

✅ mockups/login.png を作成しました
```

---

## 実装ガイドライン

### 1. 構造から始める
まずレイアウトとスペーシングを決定。装飾は最後。

### 2. 本物のコンテンツを使う
「Lorem ipsum」ではなく、実際のコピーライティングを意識。

### 3. 状態を考慮する
- Empty state
- Loading state
- Error state
- Success state

### 4. アクセシビリティ
- 十分なコントラスト比
- フォーカス状態の可視化
- セマンティックHTML

---

## 出力例

```
> /frontend-design ユーザープロフィールカード --style minimal

生成中...

✅ コンポーネント生成完了

📁 出力ファイル:
  - components/ProfileCard.tsx
  - components/ProfileCard.stories.tsx (Storybook)

🎨 スタイル: Minimal
📐 レスポンシブ: sm, md, lg
♿ アクセシビリティ: WCAG 2.1 AA
```

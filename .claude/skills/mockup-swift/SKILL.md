---
name: mockup-swift
description: SwiftUI PreviewでiOS/macOSモックアップをPNG生成
---

# /mockup-swift スキル

SwiftUIコードからネイティブ品質のモックアップ画像を生成します。

## 使用方法

```
/mockup-swift ログイン画面
/mockup-swift ダッシュボード --device "iPhone 15 Pro"
/mockup-swift 設定画面 --device "iPad Pro 12.9"
```

## 必要条件

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## デバイスプリセット

| デバイス | サイズ | 用途 |
|---------|--------|------|
| `iPhone SE` | 375x667 | 小型iPhone |
| `iPhone 15` | 393x852 | 標準iPhone |
| `iPhone 15 Pro` | 393x852 | Pro iPhone（デフォルト） |
| `iPhone 15 Pro Max` | 430x932 | 大型iPhone |
| `iPad Pro 11` | 834x1194 | 11インチiPad |
| `iPad Pro 12.9` | 1024x1366 | 12.9インチiPad |

## 実装フロー

```
[1] SwiftUI コード生成（#Preview付き）
[2] Swift スクリプトでImageRenderer実行
[3] PNG画像として保存
[4] mockups/{name}-ios.png 出力
```

---

## デザインガイドライン

### Human Interface Guidelines準拠

```swift
// ✅ SF Symbols を使用
Image(systemName: "person.circle.fill")

// ✅ 標準コンポーネント活用
TextField("", text: $text)
    .textFieldStyle(.roundedBorder)

// ✅ システムカラー使用
.foregroundStyle(.primary)
.tint(.accentColor)

// ❌ ハードコードカラーを避ける
.foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.8))
```

### スペーシング

```swift
// 標準スペーシング値
VStack(spacing: 8)   // 小
VStack(spacing: 16)  // 中
VStack(spacing: 24)  // 大
VStack(spacing: 32)  // 特大

// パディング
.padding()           // 16pt (標準)
.padding(.horizontal, 20)
```

### タイポグラフィ

```swift
// Dynamic Type対応
.font(.largeTitle)      // 34pt
.font(.title)           // 28pt
.font(.title2)          // 22pt
.font(.title3)          // 20pt
.font(.headline)        // 17pt semibold
.font(.body)            // 17pt
.font(.callout)         // 16pt
.font(.subheadline)     // 15pt
.font(.footnote)        // 13pt
.font(.caption)         // 12pt
.font(.caption2)        // 11pt
```

---

## コンポーネントライブラリ

### ボタン

```swift
// Primary
Button("続ける") { }
    .buttonStyle(.borderedProminent)

// Secondary
Button("キャンセル") { }
    .buttonStyle(.bordered)

// Destructive
Button("削除", role: .destructive) { }
    .buttonStyle(.bordered)

// Custom
Button(action: {}) {
    Text("カスタム")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.indigo)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
```

### 入力フィールド

```swift
// 標準
TextField("メールアドレス", text: $email)
    .textFieldStyle(.roundedBorder)
    .textContentType(.emailAddress)
    .keyboardType(.emailAddress)

// カスタム
TextField("検索", text: $query)
    .padding(12)
    .background(.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 10))

// SecureField
SecureField("パスワード", text: $password)
    .textFieldStyle(.roundedBorder)
    .textContentType(.password)
```

### カード

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("タイトル")
        .font(.headline)
    Text("説明テキスト")
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
.padding()
.frame(maxWidth: .infinity, alignment: .leading)
.background(.background)
.clipShape(RoundedRectangle(cornerRadius: 12))
.shadow(color: .black.opacity(0.05), radius: 8, y: 2)
```

### リスト

```swift
List {
    Section("セクション") {
        Label("項目1", systemImage: "star")
        Label("項目2", systemImage: "heart")
        Label("項目3", systemImage: "bookmark")
    }
}
.listStyle(.insetGrouped)
```

### ナビゲーション

```swift
NavigationStack {
    List { ... }
        .navigationTitle("設定")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("保存") { }
            }
        }
}
```

### タブバー

```swift
TabView {
    HomeView()
        .tabItem {
            Label("ホーム", systemImage: "house")
        }

    ProfileView()
        .tabItem {
            Label("プロフィール", systemImage: "person")
        }
}
```

---

## カラーパレット

### システムカラー（推奨）

```swift
.foregroundStyle(.primary)      // ラベル
.foregroundStyle(.secondary)    // サブテキスト
.foregroundStyle(.tertiary)     // プレースホルダ

.background(.background)        // 背景
.background(.secondaryBackground) // セカンダリ背景

.tint(.accentColor)             // アクセント
```

### カスタムカラー（必要時のみ）

```swift
extension Color {
    static let brand = Color("Brand")  // Assets.xcassets から

    // または直接定義
    static let brandIndigo = Color(
        light: Color(hex: "6366f1"),
        dark: Color(hex: "818cf8")
    )
}
```

---

## Dark Mode対応

```swift
#Preview {
    LoginView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoginView()
        .preferredColorScheme(.dark)
}
```

---

## 出力例

```
> /mockup-swift ログイン画面

📱 SwiftUIモックアップ生成中...

[1/3] SwiftUIコード生成中...
[2/3] ImageRendererでレンダリング中...
[3/3] PNG保存中...

✅ mockups/login-ios.png を作成しました (393x852)
✅ mockups/login-ios-dark.png を作成しました (393x852)

📁 生成ファイル:
  - Sources/Views/LoginView.swift
  - mockups/login-ios.png
  - mockups/login-ios-dark.png

📎 設計書に追加:
| Light | Dark |
|-------|------|
| ![](./mockups/login-ios.png) | ![](./mockups/login-ios-dark.png) |
```

---

## Web版との使い分け

| 用途 | 推奨スキル |
|------|-----------|
| Webアプリ、LP | `/mockup` (HTML/Tailwind) |
| iOSアプリ | `/mockup-swift` |
| クロスプラットフォーム | 両方生成して比較 |

```
# Web版
/mockup ログイン画面

# iOS版
/mockup-swift ログイン画面

# 両方（並列実行）
/mockup ログイン画面 && /mockup-swift ログイン画面
```

# StressAgent Pro

AI駆動型メンタルヘルスSaaSアプリケーション

[![CI](https://github.com/AI-Driven-School/aiki/actions/workflows/ci.yml/badge.svg)](https://github.com/AI-Driven-School/aiki/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🚀 今すぐ始める

**初めての方はこちら** → [**超初心者向けセットアップガイド**](docs/QUICKSTART.md)

プログラミング経験がなくても、ステップバイステップで動かせます！

---

## 📖 このアプリについて

StressAgent Pro は、**会社の従業員のメンタルヘルス（心の健康）を守るためのアプリ**です。

### できること

| 機能 | 説明 |
|------|------|
| 📋 **ストレスチェック** | 57問の質問に答えると、ストレス状態が分かります |
| 🤖 **AIカウンセリング** | 24時間いつでもAIに相談できます |
| 📊 **ダッシュボード** | 管理者は会社全体のストレス状況を確認できます |
| 💡 **AI改善提案** | データを元に、職場環境の改善方法を提案します |
| 📱 **連携機能** | Slack、Teams、LINE、Discord と連携できます |

### 画面イメージ

```
┌─────────────────────────────────────┐
│  StressAgent Pro                    │
├─────────────────────────────────────┤
│                                     │
│  📊 ダッシュボード                  │
│  ┌─────────┐ ┌─────────┐           │
│  │総従業員 │ │高ストレス│           │
│  │  100名  │ │   15名  │           │
│  └─────────┘ └─────────┘           │
│                                     │
│  🏢 部署別ストレス状況              │
│  ■■■■■■■■░░ 営業部 75点            │
│  ■■■■░░░░░░ 開発部 45点            │
│  ■■■░░░░░░░ 人事部 30点            │
│                                     │
└─────────────────────────────────────┘
```

---

## 💻 必要なもの

このアプリを動かすには、以下のソフトウェアが必要です：

| ソフトウェア | バージョン | 何に使う？ |
|-------------|-----------|-----------|
| Python | 3.11以上 | サーバー（バックエンド）を動かす |
| Node.js | 20以上 | 画面（フロントエンド）を動かす |
| PostgreSQL | 15以上 | データを保存する |

> **インストール方法が分からない？** → [超初心者向けガイド](docs/QUICKSTART.md) で詳しく説明しています！

---

## ⚡ クイックスタート（経験者向け）

```bash
# 1. ダウンロード
git clone https://github.com/AI-Driven-School/aiki.git
cd aiki/benchmarks/complex-test

# 2. バックエンド
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
echo "JWT_SECRET_KEY=$(openssl rand -hex 32)" >> .env
createdb stressagent && alembic upgrade head

# 3. フロントエンド（別ターミナル）
cd frontend
npm install && cp .env.example .env.local

# 4. 起動
# ターミナル1: cd backend && uvicorn app.main:app --reload
# ターミナル2: cd frontend && npm run dev

# 5. ブラウザで http://localhost:3000 を開く
```

---

## 📚 ドキュメント一覧

| ドキュメント | 対象者 | 内容 |
|-------------|--------|------|
| [超初心者向けガイド](docs/QUICKSTART.md) | 🔰 初心者 | インストールから起動まで丁寧に解説 |
| [開発環境構築](docs/DEVELOPMENT.md) | 👨‍💻 開発者 | 開発者向けの詳細なセットアップ |
| [アーキテクチャ](docs/ARCHITECTURE.md) | 🏗️ 開発者 | システム設計・構成図 |
| [API リファレンス](docs/API.md) | 👨‍💻 開発者 | REST API の詳細 |
| [デプロイ手順](docs/DEPLOYMENT.md) | 🚀 運用者 | 本番環境へのデプロイ方法 |

---

## 🔧 技術スタック

<details>
<summary>クリックして詳細を表示</summary>

| レイヤー | 技術 | 説明 |
|----------|------|------|
| フロントエンド | Next.js 14, React 18, TypeScript | 画面を作る技術 |
| バックエンド | FastAPI, Python 3.11, SQLAlchemy | サーバー側の処理 |
| データベース | PostgreSQL | データを保存 |
| AI | OpenAI GPT-4o-mini | AIチャット・分析 |
| 認証 | JWT (HttpOnly Cookie) | ログイン管理 |
| デプロイ | Vercel, Railway | 本番環境 |

</details>

---

## 📁 フォルダ構成

```
StressAgent Pro/
│
├── 📂 backend/          ← サーバー側のプログラム
│   ├── app/             ← メインのコード
│   └── tests/           ← テストコード
│
├── 📂 frontend/         ← 画面側のプログラム
│   ├── app/             ← ページ
│   └── components/      ← 部品（ボタンなど）
│
├── 📂 docs/             ← ドキュメント
│
└── 📄 README.md         ← このファイル
```

---

## 🔒 セキュリティ

このアプリは以下のセキュリティ対策を実装しています：

- ✅ パスワードは暗号化して保存
- ✅ 強力なパスワードを要求（大文字・小文字・数字・記号）
- ✅ 連続ログイン試行を制限（ブルートフォース対策）
- ✅ 個人情報はAIに送る前にフィルタリング

---

## 🧪 テスト

```bash
# バックエンドのテスト
cd backend
pytest tests/ -v

# フロントエンドのテスト
cd frontend
npm test
```

---

## 🤝 貢献したい方へ

1. このリポジトリを**フォーク**（自分のアカウントにコピー）
2. 新しいブランチを作成: `git checkout -b feature/新機能`
3. 変更をコミット: `git commit -m '新機能を追加'`
4. プッシュ: `git push origin feature/新機能`
5. **プルリクエスト**を作成

---

## 📜 ライセンス

[MIT License](LICENSE) - 自由に使用・改変・配布できます。

---

## ⚠️ 注意事項

- このアプリは**医療診断を行うものではありません**
- 深刻なメンタルヘルスの問題がある場合は、**専門家（医師・カウンセラー）に相談してください**

---

## 💬 困ったときは

- **バグ報告・質問**: [GitHub Issues](https://github.com/AI-Driven-School/aiki/issues)
- **ドキュメント**: [docs/](docs/) フォルダを確認

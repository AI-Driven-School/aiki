# StressAgent Pro - 超初心者向けセットアップガイド

このガイドでは、プログラミング経験がなくても StressAgent Pro を動かせるよう、一つずつ丁寧に説明します。

---

## 目次

1. [必要なソフトウェアのインストール](#1-必要なソフトウェアのインストール)
2. [プロジェクトのダウンロード](#2-プロジェクトのダウンロード)
3. [バックエンド（サーバー）の準備](#3-バックエンドサーバーの準備)
4. [フロントエンド（画面）の準備](#4-フロントエンド画面の準備)
5. [アプリを起動する](#5-アプリを起動する)
6. [よくあるエラーと解決方法](#6-よくあるエラーと解決方法)

---

## 1. 必要なソフトウェアのインストール

### 1.1 Python（パイソン）のインストール

Python はバックエンド（サーバー側）で使うプログラミング言語です。

**Mac の場合：**

1. ターミナルを開く（Spotlight で「ターミナル」と検索）
2. 以下のコマンドをコピーして貼り付け、Enter を押す：

```bash
# Homebrew をインストール（まだの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Python をインストール
brew install python@3.11
```

3. インストール確認：
```bash
python3 --version
```
→ `Python 3.11.x` と表示されれば成功！

**Windows の場合：**

1. https://www.python.org/downloads/ にアクセス
2. 「Download Python 3.11.x」をクリック
3. ダウンロードしたファイルを実行
4. **重要**: 「Add Python to PATH」にチェックを入れてからインストール

---

### 1.2 Node.js（ノードジェイエス）のインストール

Node.js はフロントエンド（画面側）で使う実行環境です。

**Mac の場合：**

```bash
brew install node@20
```

**Windows の場合：**

1. https://nodejs.org/ にアクセス
2. 「LTS」と書かれた緑のボタンをクリック
3. ダウンロードしたファイルを実行してインストール

**確認：**
```bash
node --version
```
→ `v20.x.x` と表示されれば成功！

---

### 1.3 PostgreSQL（ポストグレス）のインストール

PostgreSQL はデータを保存するデータベースです。

**Mac の場合：**

```bash
brew install postgresql@15
brew services start postgresql@15
```

**Windows の場合：**

1. https://www.postgresql.org/download/windows/ にアクセス
2. 「Download the installer」をクリック
3. インストーラーを実行（パスワードは覚えておいてください）

---

## 2. プロジェクトのダウンロード

### 2.1 ターミナルでダウンロード先に移動

```bash
# デスクトップに移動
cd ~/Desktop
```

### 2.2 プロジェクトをダウンロード

```bash
git clone https://github.com/AI-Driven-School/claude-codex-collab.git
cd claude-codex-collab/benchmarks/complex-test
```

> **git がないと言われたら：**
> - Mac: `brew install git`
> - Windows: https://git-scm.com/download/win からインストール

---

## 3. バックエンド（サーバー）の準備

### 3.1 バックエンドフォルダに移動

```bash
cd backend
```

### 3.2 仮想環境を作成

仮想環境とは、このプロジェクト専用の作業スペースです。

```bash
python3 -m venv venv
```

### 3.3 仮想環境を有効化

**Mac の場合：**
```bash
source venv/bin/activate
```

**Windows の場合：**
```bash
venv\Scripts\activate
```

→ プロンプトの先頭に `(venv)` が表示されれば成功！

### 3.4 必要なパッケージをインストール

```bash
pip install -r requirements.txt
```

→ たくさんの文字が流れますが、エラーが出なければOK！

### 3.5 設定ファイルを作成

```bash
cp .env.example .env
```

### 3.6 秘密鍵を生成して設定

```bash
# 秘密鍵を生成
openssl rand -hex 32
```

→ 出力された長い文字列をコピー

次に `.env` ファイルを編集：

```bash
# Mac
open -e .env

# Windows
notepad .env
```

`JWT_SECRET_KEY=` の後に、コピーした文字列を貼り付けて保存。

例：
```
JWT_SECRET_KEY=a1b2c3d4e5f6...（生成した文字列）
```

### 3.7 データベースを作成

```bash
# データベースを作成
createdb stressagent

# テーブルを作成
alembic upgrade head
```

---

## 4. フロントエンド（画面）の準備

### 4.1 フロントエンドフォルダに移動

```bash
# backendフォルダにいる場合
cd ../frontend
```

### 4.2 必要なパッケージをインストール

```bash
npm install
```

→ 数分かかります。エラーが出なければOK！

### 4.3 設定ファイルを作成

```bash
cp .env.example .env.local
```

---

## 5. アプリを起動する

**2つのターミナルウィンドウが必要です！**

### ターミナル1: バックエンドを起動

```bash
cd ~/Desktop/claude-codex-collab/benchmarks/complex-test/backend
source venv/bin/activate  # Mac
# venv\Scripts\activate  # Windows
uvicorn app.main:app --reload --port 8000
```

→ 以下のように表示されれば成功：
```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### ターミナル2: フロントエンドを起動

新しいターミナルウィンドウを開いて：

```bash
cd ~/Desktop/claude-codex-collab/benchmarks/complex-test/frontend
npm run dev
```

→ 以下のように表示されれば成功：
```
▲ Next.js 14.0.4
- Local: http://localhost:3000
```

### 5.3 ブラウザでアクセス

1. ブラウザ（Chrome, Safari など）を開く
2. アドレスバーに `http://localhost:3000` と入力
3. Enter を押す

**おめでとうございます！** StressAgent Pro が表示されました！

---

## 6. よくあるエラーと解決方法

### エラー: `command not found: python3`

**原因**: Python がインストールされていない、またはパスが通っていない

**解決方法**:
- Mac: `brew install python@3.11`
- Windows: Python を再インストールし、「Add to PATH」にチェック

---

### エラー: `ModuleNotFoundError: No module named 'xxx'`

**原因**: 仮想環境が有効になっていない

**解決方法**:
```bash
source venv/bin/activate  # Mac
venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

---

### エラー: `RuntimeError: JWT_SECRET_KEY environment variable is required`

**原因**: 秘密鍵が設定されていない

**解決方法**:
1. `.env` ファイルを開く
2. `JWT_SECRET_KEY=` の後に値があるか確認
3. なければ `openssl rand -hex 32` で生成して貼り付け

---

### エラー: `EADDRINUSE: address already in use`

**原因**: すでに同じポートでアプリが動いている

**解決方法**:
```bash
# Mac: ポート8000を使っているプロセスを終了
lsof -ti:8000 | xargs kill

# ポート3000を使っているプロセスを終了
lsof -ti:3000 | xargs kill
```

---

### エラー: `createdb: command not found`

**原因**: PostgreSQL がインストールされていない

**解決方法**:
- Mac: `brew install postgresql@15 && brew services start postgresql@15`
- Windows: PostgreSQL を再インストール

---

### 画面が真っ白になる

**原因**: フロントエンドがバックエンドに接続できていない

**確認方法**:
1. ターミナル1でバックエンドが起動しているか確認
2. `http://localhost:8000/docs` にアクセスしてAPIドキュメントが表示されるか確認

---

## 次のステップ

セットアップが完了したら：

1. **ユーザー登録**: http://localhost:3000/register で企業・管理者アカウントを作成
2. **ログイン**: 作成したアカウントでログイン
3. **ストレスチェック**: 従業員としてストレスチェックを受験
4. **ダッシュボード**: 管理者として結果を確認

---

## 困ったときは

- **GitHub Issues**: https://github.com/AI-Driven-School/claude-codex-collab/issues
- 上記で解決しない場合は Issue を作成してください

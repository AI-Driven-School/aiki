---
name: api
description: API設計書を生成（Claude）
---

# /api スキル

エンドポイント名からOpenAPI仕様書を生成します。

## 使用方法

```
/api auth
/api users
/api products
```

## 出力テンプレート

`docs/api/{endpoint}.yaml` に出力:

```yaml
openapi: 3.0.0
info:
  title: {機能名} API
  version: 1.0.0
  description: {APIの概要}

servers:
  - url: /api/v1
    description: API v1

paths:
  /{endpoint}:
    get:
      summary: {概要}
      description: {詳細説明}
      tags:
        - {タグ}
      parameters:
        - name: {パラメータ名}
          in: query
          required: false
          schema:
            type: string
          description: {説明}
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Schema名}'
        '401':
          description: 認証エラー
        '500':
          description: サーバーエラー

    post:
      summary: {概要}
      description: {詳細説明}
      tags:
        - {タグ}
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/{Request Schema}'
      responses:
        '201':
          description: 作成成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/{Response Schema}'
        '400':
          description: バリデーションエラー
        '401':
          description: 認証エラー

components:
  schemas:
    {Schema名}:
      type: object
      required:
        - {必須フィールド}
      properties:
        id:
          type: string
          format: uuid
          description: 一意識別子
        {フィールド名}:
          type: {型}
          description: {説明}
        createdAt:
          type: string
          format: date-time
          description: 作成日時
        updatedAt:
          type: string
          format: date-time
          description: 更新日時

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

## 生成ガイドライン

1. **RESTful原則**: リソース指向のエンドポイント設計
2. **一貫性**: 命名規則、レスポンス形式を統一
3. **エラーハンドリング**: 標準的なHTTPステータスコード使用
4. **セキュリティ**: 認証が必要なエンドポイントを明記

## 出力例

```
> /api auth

📋 API設計を生成中... (Claude)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 docs/api/auth.yaml を作成しました
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

openapi: 3.0.0
info:
  title: 認証 API
  version: 1.0.0

paths:
  /auth/login:
    post:
      summary: ログイン
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  minLength: 8
      responses:
        '200':
          description: ログイン成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  token:
                    type: string
                  user:
                    $ref: '#/components/schemas/User'
...

承認しますか？ [Y/n/reject 理由]
```

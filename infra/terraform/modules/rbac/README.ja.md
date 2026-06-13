# RBAC モジュール

このモジュールは、Microsoft Foundry リソースに対する Azure ロールベースアクセス制御 (RBAC) のロール割り当てを管理します。

## 概要

このモジュールは、Foundry Account および Foundry Project スコープにおいて、ユーザープリンシパルとセキュリティグループに Azure 組み込みロールを割り当てます。

## Foundry 組み込みロール（最新）

> **重要**: Foundry RBAC ロールは最近リネームされました。ロール ID と基本的な権限は変更されていません。リネームのロールアウト中は、ロール名の代わりに**ロール定義 ID（GUID）**を使用することが推奨されています。

| 旧名称                   | 新名称                      | GUID                                   |
| ------------------------ | --------------------------- | -------------------------------------- |
| Azure AI User            | **Foundry User**            | `53ca6127-db72-4b80-b1b0-d745d6d5456d` |
| Azure AI Owner           | **Foundry Owner**           | `c883944f-8b7b-4483-af10-35834be79c4a` |
| Azure AI Account Owner   | **Foundry Account Owner**   | `e47c6f54-e4a2-4754-9501-8e0985b135e1` |
| Azure AI Project Manager | **Foundry Project Manager** | `eadc314b-1a2d-4efa-be10-5d325db5065e` |

### ロールの説明

| ロール                      | 説明                                                                                                                                 |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Foundry User**            | Foundry プロジェクトおよびアカウントへの閲覧アクセスと、Foundry プロジェクトのデータアクション権限を付与。最小権限アクセスロール。   |
| **Foundry Project Manager** | Foundry プロジェクトに対する管理アクションと開発者アクションを実行可能。他のユーザーに Foundry User ロールを条件付きで割り当て可能。 |
| **Foundry Account Owner**   | プロジェクトとアカウントの完全管理アクセスを付与。Foundry User、ACR、モニタリングロールを条件付きで割り当て可能。                    |
| **Foundry Owner**           | プロジェクトとアカウントの完全管理・開発アクセスを付与。高権限のセルフサーブロール。                                                 |

### 権限マトリックス

| 機能                                     | Foundry User | Foundry Project Manager |      Foundry Account Owner      |          Foundry Owner          |
| ---------------------------------------- | :----------: | :---------------------: | :-----------------------------: | :-----------------------------: |
| Foundry リソースの読み取り               |      ✔       |            ✔            |                ✔                |                ✔                |
| データアクション（推論、エージェント等） |      ✔       |            ✔            |                ✔                |                ✔                |
| プロジェクトの作成・管理                 |              |            ✔            |                ✔                |                ✔                |
| Foundry アカウントの管理                 |              |                         |                ✔                |                ✔                |
| ロールの割り当て（条件付き）             |              |    Foundry User のみ    | Foundry User, ACR, モニタリング | Foundry User, ACR, モニタリング |
| モデルのデプロイ（コントロールプレーン） |              |                         |                ✔                |                ✔                |

## 公式ドキュメントからの重要な注意事項

> `Cognitive Services` で始まる組み込みロールは、Foundry シナリオでは**割り当てないでください**。これらのロールは AI Services リソースへの直接アクセス用に設計されており、Foundry には適用されません。
>
> `Azure AI Developer` ロールも Foundry の作業には**使用しないでください**。名前にもかかわらず、このロールは Azure Machine Learning ワークスペースと Foundry Hub（クラシック）にスコープされ、Foundry プロジェクトや Hosted Agent には適用されません。Foundry プロジェクトへのアクセスには、**Foundry User** または **Foundry Owner** を使用してください。

## 推奨エンタープライズ RBAC マッピング

| ペルソナ                    | ロール                  | スコープ                                |
| --------------------------- | ----------------------- | --------------------------------------- |
| IT 管理者                   | Owner                   | サブスクリプション                      |
| マネージャー                | Foundry Account Owner   | Foundry リソース                        |
| チームリード / リード開発者 | Foundry Project Manager | Foundry リソース                        |
| チームメンバー / 開発者     | Foundry User + Reader   | プロジェクトスコープ + Foundry リソース |

### アクセス分離パターン

- **分離なし**: 全ユーザーに `Foundry Owner` をリソーススコープで付与。
- **部分分離**: 管理者に `Foundry Account Owner`、開発者/PM に `Foundry Project Manager` を付与。
- **完全分離**: 管理者に `Foundry Account Owner`（リソーススコープ）、開発者に `Reader`（Foundry リソース）+ `Foundry User`（プロジェクトスコープ）、PM に `Foundry Project Manager`（リソーススコープ）を付与。

## モジュールの使用方法

### 入力変数

| 変数                         | 説明                                                                                 | デフォルト |
| ---------------------------- | ------------------------------------------------------------------------------------ | ---------- |
| `foundry_account_id`         | Foundry Account のリソース ID（RBAC スコープ）                                       | —          |
| `foundry_project_id`         | Foundry Project のリソース ID（RBAC スコープ）                                       | —          |
| `deployer_principal_id`      | デプロイヤーのプリンシパル ID（空文字でスキップ）                                    | `""`       |
| `deployer_use_foundry_owner` | true の場合、Foundry Account Owner の代わりに Foundry Owner をデプロイヤーに割り当て | `false`    |
| `foundry_developer_group_id` | Foundry 開発者グループのオブジェクト ID（空文字でスキップ）                          | `""`       |
| `foundry_user_group_id`      | Foundry ユーザーグループのオブジェクト ID（空文字でスキップ）                        | `""`       |

### ロール割り当て（完全分離パターン）

このモジュールは、Microsoft が推奨する公式の「完全アクセス分離」パターンに従います。

| プリンシパル     | 対象スコープ    | ロール                                                  | GUID                            |
| ---------------- | --------------- | ------------------------------------------------------- | ------------------------------- |
| デプロイヤー     | Foundry Account | Foundry Account Owner（デフォルト）または Foundry Owner | `e47c6f54-...` / `c883944f-...` |
| 開発者グループ   | Foundry Account | Foundry Project Manager                                 | `eadc314b-...`                  |
| 開発者グループ   | Foundry Project | Foundry Project Manager                                 | `eadc314b-...`                  |
| ユーザーグループ | Foundry Account | Reader                                                  | `acdd72a7-...`                  |
| ユーザーグループ | Foundry Project | Foundry User                                            | `53ca6127-...`                  |

> **注**: すべてのロール割り当ては、Foundry RBAC ロールリネームのロールアウト中の安定性のため、`role_definition_id`（GUID ベース）を使用しています。

## 参考資料

- [Role-based access control for Microsoft Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry)（更新日: 2026-05-16）
- [Azure built-in roles for AI + machine learning](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/ai-machine-learning)（更新日: 2026-04-09）
- [Role-based access control for Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/role-based-access-control)
- [What is Azure RBAC?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)

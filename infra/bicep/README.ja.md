# Microsoft Foundry - Bicep Infrastructure as Code

このディレクトリには Microsoft Foundry の展開の Bicep IaC コードが含まれています。

## 1. 開発環境

### 1.1. Dev Container で開く

このプロジェクトは Dev Container に対応しており、必要なツールが自動的にセットアップされます。
Dev Container の設定は `.devcontainer/devcontainer.json` にあります。

> :bulb: **Dev Container とは？**
>
> Dev Container (Development Container) は、Docker コンテナを使用して、
> 開発環境を完全に再現可能な形でパッケージ化する仕組みです。
> これにより、チームメンバー全員が同じ開発環境を簡単に構築でき、
> 「自分の環境では動くのに...」という問題を回避できます。
> 詳細は [VS Code Dev Containers ドキュメント][devcontainer-docs] を参照してください。
>
> [devcontainer-docs]: https://code.visualstudio.com/docs/devcontainers/containers

#### 1.1.1 インストールされるツール

| ツール           | バージョン | 説明                                          |
| ---------------- | ---------- | --------------------------------------------- |
| Python           | 3.12       | プログラミング言語ランタイム                  |
| uv               | latest     | Python パッケージマネージャー                 |
| Terraform        | 1.9        | IaC ツール。Azureリソースを宣言的に定義・管理 |
| TFLint           | latest     | Terraformコードの静的解析ツール               |
| Azure CLI        | latest     | AzureリソースをCLIから管理するツール          |
| Git & Zsh        | -          | バージョン管理とシェル環境                    |
| Docker-in-Docker | latest     | コンテナ内でDockerを使用可能にする機能        |
| Node.js          | LTS        | JavaScript ランタイム                         |

> :information_source: **Bicep CLI について**
>
> Bicep CLI は Azure CLI に含まれているため、別途インストールは不要です。
> `az bicep version` で確認できます。

#### 1.1.2 使用方法

**前提条件：**

- [Docker Desktop][docker-desktop] がインストール・起動されていること
- VS Code に [Dev Containers 拡張機能][devcontainers-ext] が
  インストールされていること

[docker-desktop]: https://www.docker.com/products/docker-desktop/
[devcontainers-ext]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

**Dev Containerで開く（Bicep 実行・本格開発）：**

1. VS Codeで **File > Open Folder**
2. リポジトリのルートフォルダを開く
3. Ctrl+Shift+P → 「**Dev Containers: Reopen in Container**」を選択
4. `Microsoft Foundry Workshop` コンテナを選択
5. 必要なツールが自動的にセットアップされる（初回は数分かかる場合があります）

> :hourglass_flowing_sand: **初回起動時の注意**
>
> 初回はコンテナイメージのダウンロードとビルドが行われるため、5〜10分程度かかることがあります。
> 2回目以降はキャッシュが使用されるため、高速に起動します。

### 1.2. 通常の VS Code 環境で開く

このプロジェクト用に VS Code Workspace ファイルが用意されており、通常の VS Code 環境 (Dev Containerなし) で動作します。
VS Code のワークスペース機能は、複数プロジェクトの横断的な閲覧に便利となっています。
Bicep 実行には、手動でツールのインストールが必要です。

#### 1.2.1 インストールを推奨するツール

Dev Containerを使用しない場合は、以下のツールを手動でインストールしてください：

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)（Bicep CLI を含む）
- [Bicep VS Code 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep)

推奨される VS Code 拡張機能（.vscode/extensions.jsonで自動推奨）：

- Bicep
- Azure CLI Tools
- YAML

#### 1.2.2 使用方法

**VS Code Workspace ファイルで開く (コード閲覧・軽微な編集):**

1. リポジトリのルートにある `project-infra.code-workspace` を開く
2. `Foundry (Bicep IaC)` を選択する

## 2. プロジェクト構造

```text
bicep/
├── bicepconfig.json           - Bicep リンターとフォーマット設定
├── basic/
│   ├── main.bicep             - メインデプロイテンプレート（リソースグループスコープ）
│   ├── main.bicepparam        - 環境固有のパラメータ値
│   ├── main.bicepparam.example - パラメータファイルのテンプレート
│   ├── deploy.sh              - スマートデプロイラッパースクリプト
│   └── modules/
│       ├── naming.bicep               - CAF 準拠の命名関数
│       ├── types.bicep                - 共有型定義（CommonTags, ModelDeploymentConfig 等）
│       ├── regions.bicep              - Azure リージョン略称マップ
│       ├── roleDefinitions.bicep      - RBAC ロール ID 定義集
│       ├── foundry.bicep              - Foundry Account + Project + AI Search 接続
│       ├── foundry.deployments.bicep  - OpenAI モデルデプロイメント
│       ├── search.bicep               - Azure AI Search サービス
│       ├── storage.bicep              - Blob Storage アカウント
│       ├── acr.bicep                  - Container Registry（CMK サポート付き）
│       ├── keyvault.bicep             - Key Vault（RBAC モード）
│       ├── keyvault.key.bicep         - CMK 暗号化キー（ローテーション付き）
│       ├── identity.cmk.bicep         - CMK 用 User Assigned Managed Identity
│       ├── observability.bicep        - Log Analytics + Application Insights
│       ├── rbac.services.bicep        - サービス間 RBAC 割り当て
│       ├── rbac.cmk.bicep             - CMK 暗号化 RBAC
│       ├── rbac.users.bicep           - ユーザー/グループ RBAC 割り当て
│       ├── vnet.bicep                 - 仮想ネットワーク + PE サブネット
│       ├── private-dns-zone.bicep     - プライベート DNS ゾーン + VNet リンク
│       ├── private-endpoint.bicep     - 汎用プライベートエンドポイントモジュール
│       └── azuread-mip-mrms.bicep     - AI Search 秘密度ラベル用 MIP/MRMS アプリロール
```

## 3. IaC による Azure へのリソースの展開

### 3.1. Azure ログイン認証

Bicep のデプロイ時、既定では Azure CLI のログイン認証済みのコンテキストを使用します。

以下のコマンドでログインしてください：

```bash
az login --tenant <tenant-id>
```

> :key: **`<tenant-id>` について**
>
> `<tenant-id>` は Azure Active Directory (Entra ID) のテナント識別子です。
> テナントIDがわからない場合は、管理者に確認するか、
> [Azure Portal](https://portal.azure.com) の「Microsoft Entra ID」→「概要」
> で確認できます。

ログイン後、正しいサブスクリプションが選択されているか確認してください：

```bash
# 現在のアカウント情報を表示
az account show

# サブスクリプション一覧を表示
az account list --output table

# 必要に応じてサブスクリプションを切り替え
az account set --subscription <subscription-id or name>
```

Dev Container 使用時は、ホストマシンの `~/.azure` フォルダが自動的にマウントされ、以前に実行した Azure CLI のログイン認証のコンテキストが引き継がれます。

### 3.2 展開する IaC モジュールの選択

Microsoft Foundry を展開するモジュールを選択します。
現在は、以下のモジュールがあります：

- [ベーシック](./basic/)

```bash
cd <project-root>/infra/bicep/basic
```

### 3.3 パラメータファイルの準備

サンプルパラメータファイルをコピーして内容を変更してください。

```bash
cp main.bicepparam.example main.bicepparam
```

`main.bicepparam` を編集して、必要なパラメータを設定します：

```bicep
using './main.bicep'

// 必須パラメータ
param env = 'poc'                                          // dev | stg | poc | prd
param project = 'foundry'                                  // プロジェクト略称（8文字以下推奨）
param foundryProjectDisplayName = 'Foundry PoC'            // Foundry ポータルの表示名
param foundryProjectDescription = 'Foundry PoC project'    // プロジェクト説明
param location = 'eastus2'                                 // Azure リージョン

// オプション：監視
param createObservability = true

// オプション：モデルデプロイメント
param modelDeployments = [
  {
    name: 'gpt-4.1'
    modelName: 'gpt-4.1'
    modelVersion: '2025-04-14'
    skuName: 'GlobalStandard'
    capacity: 100
  }
]

// オプション：AI Search
param enableAiSearch = true

// オプション：カスタマーマネージドキー暗号化
param enableCmk = true
param enableCmkAutoRotation = true
```

### 3.4 デプロイスクリプトによるデプロイ（推奨）

`deploy.sh` スクリプトは、ソフト削除されたリソースを自動的に検出・処理する
スマートデプロイラッパーを提供します。

```bash
export RG="<リソースグループ名>"
export deployerObjectId="<Entra ID オブジェクト ID>"
export LOCATION="eastus2"

# オプション：Azure AD グループ ID
export aiDeveloperGroupId="<開発者グループのオブジェクト ID>"
export aiUserGroupId="<ユーザーグループのオブジェクト ID>"

bash deploy.sh
```

スクリプトは以下の 3 ステッププロセスを実行します：

1. **名前解決**: `az deployment group what-if` を実行し、Bicep テンプレートからリソース名
   （`uniqueString()` ハッシュを含む）を解決
2. **ソフト削除検出**: デプロイと競合するソフト削除された Key Vault と Cognitive Services を
   チェックし、自動的に復元フラグを設定
3. **デプロイ**: 必要な復元パラメータを含めて `az deployment group create` を実行

> :information_source: **環境変数について**
>
> | 変数                 | 必須   | 説明                                                           |
> | -------------------- | ------ | -------------------------------------------------------------- |
> | `RG`                 | はい   | デプロイ先のリソースグループ名                                 |
> | `deployerObjectId`   | はい   | デプロイヤーの Entra ID オブジェクト ID（RBAC 割り当て用）     |
> | `LOCATION`           | はい   | ソフト削除の検索に使用する Azure リージョン                    |
> | `aiDeveloperGroupId` | いいえ | AI 開発者グループの Entra ID オブジェクト ID                   |
> | `aiUserGroupId`      | いいえ | AI ユーザーグループの Entra ID オブジェクト ID（読み取り専用） |
> | `DEPLOYMENT_NAME`    | いいえ | デプロイ名のプレフィックス（省略時は自動生成）                 |

### 3.5 Azure CLI による手動デプロイ

ラッパースクリプトを使用せずに手動でデプロイする場合：

```bash
# デプロイの事前確認
az deployment group what-if \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="<Entra ID オブジェクト ID>"

# デプロイ
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="<Entra ID オブジェクト ID>"
```

> :warning: **注意**
>
> デプロイには数分〜数十分かかる場合があります。プロセスを中断しないでください。
> 中断すると、リソースの状態が不整合になる可能性があります。

### 3.6 ソフト削除されたリソースの処理

以前の削除後に再デプロイする場合、Azure がリソースをソフト削除状態で保持していることがあります。
ソフト削除リソースに関するエラーが発生した場合は、
復元パラメータを追加してください：

```bash
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="..." \
  --parameters keyvaultRestore=true \
  --parameters foundryRestore=true
```

> :bulb: **ヒント**
>
> `deploy.sh` スクリプトはソフト削除されたリソースを自動的に検出し、
> これらのパラメータを設定するため、通常は手動操作は不要です。

### 3.7. デプロイしたリソース削除

```bash
az group delete --name $RG
```

> :rotating_light: **重要な警告**
>
> このコマンドは、リソースグループとその中のすべてのリソースを**完全に削除**します。
>
> - 削除したリソースは復元できません（ソフト削除された Key Vault と Cognitive Services を除く）
> - 本番環境では特に慎重に実行してください
>
> 選択的にクリーンアップする場合は、Azure Portal や CLI で個別のリソースを先に削除してください。

## 4. コード品質チェック

### Bicep リンター

`bicepconfig.json` によりセキュリティと品質ルールが適用されます：

| ルール                                | レベル  | 説明                                       |
| ------------------------------------- | ------- | ------------------------------------------ |
| `adminusername-should-not-be-literal` | error   | ハードコードされた管理者ユーザー名を防止   |
| `no-hardcoded-env-urls`               | error   | Azure 環境 URL のハードコード禁止          |
| `no-hardcoded-location`               | error   | ロケーションはパラメータ化が必須           |
| `secure-parameter-default`            | error   | セキュアパラメータにデフォルト値を設定禁止 |
| `no-unused-params`                    | warning | 未使用パラメータの検出                     |
| `use-recent-api-versions`             | warning | 最新の API バージョンの使用を推奨          |

リンターは Bicep 拡張機能により VS Code 上で自動的に実行されます。
CLI からチェックする場合：

```bash
az bicep build --file basic/main.bicep
```

### Pre-commit チェック

リポジトリへのコミットコマンドを実行すると、ステージ上のファイルに対して、
`pre-commit` ツールを使ってチェックが実行されます。

```bash
pre-commit run
```

## 5. トラブルシューティング

### Dev Container が起動しない

**考えられる原因と対処法：**

| 原因                           | 対処法                                                      |
| ------------------------------ | ----------------------------------------------------------- |
| Docker Desktop が停止          | Docker Desktop を起動し、ステータスバーが緑色になるまで待つ |
| WSL で Docker が未インストール | WSL 内で `docker --version` を実行して確認                  |
| Dev Containers 拡張機能がない  | VS Code の拡張機能からインストール                          |
| キャッシュの問題               | 「Dev Containers: Rebuild Container」を実行                 |

### Azure 認証エラーが発生する

**エラー例：** `Error: AADSTS700016: Application with identifier '...' was not found`

```bash
# 現在の認証状態をクリア
az logout

# 再度ログイン
az login --tenant <tenant-id>

# 認証状態を確認
az account show
```

### ソフト削除されたリソースの競合

**エラー例：** `A vault with the same name already exists in deleted state`

以前削除したリソースがソフト削除状態で残っている場合に発生します。

```bash
# 方法 1：deploy.sh を使用（推奨、自動検出）
bash deploy.sh

# 方法 2：復元パラメータを手動で追加
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters deployerObjectId="..." \
  --parameters keyvaultRestore=true \
  --parameters foundryRestore=true

# 方法 3：ソフト削除されたリソースを手動でパージ
az keyvault purge --name <vault-name> --location <location>
az cognitiveservices account purge --name <account-name> --resource-group <rg> --location <location>
```

### Bicep コンパイルエラー

**エラー例：** `Error BCP0xx: ...`

```bash
# Bicep CLI バージョンを確認
az bicep version

# Bicep CLI をアップグレード
az bicep upgrade

# テンプレートを検証
az bicep build --file basic/main.bicep
```

## 6. 用語集

初心者の方向けに、このドキュメントで使用される主な用語を説明します。

| 用語           | 説明                                                         |
| -------------- | ------------------------------------------------------------ |
| **Bicep**      | Azure リソースを宣言的にデプロイするためのドメイン固有言語   |
| **IaC**        | インフラをコードとして管理する手法                           |
| **ARM**        | Azure Resource Manager — Bicep の基盤となるデプロイエンジン  |
| **モジュール** | リソースのセットをカプセル化した再利用可能な Bicep ファイル  |
| **パラメータ** | デプロイの動作をカスタマイズする入力値                       |
| **What-If**    | 実際にデプロイせずに変更内容をプレビューする操作             |
| **CMK**        | カスタマーマネージドキー — 独自の Key Vault キーによる暗号化 |
| **RBAC**       | ロールベースのアクセス制御 — Azure の認可メカニズム          |
| **ソフト削除** | 削除されたリソースを復旧期間中に保持して回復を可能にする機能 |

## 7. 参考リンク

- [Bicep ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/)
- [Bicep リンタールール](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/linter)
- [Azure CLI ドキュメント](https://docs.microsoft.com/ja-jp/cli/azure/)
- [Azure Cognitive Services REST API](https://learn.microsoft.com/ja-jp/rest/api/cognitiveservices/)
- [Azure 初心者向けドキュメント](https://learn.microsoft.com/ja-jp/azure/)

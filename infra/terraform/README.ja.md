# Microsoft Foundry - Terraform Infrastructure as Code

このディレクトリには Microsoft Foundry の展開の Terraform IaC コードが含まれています。

## 1. 開発環境

### 1.1. Dev Container で開く

このプロジェクトは Dev Container に対応しており、必要なツールが自動的にセットアップされます。
Dev Container の設定は `.devcontainer/terraform/devcontainer.json` にあります。

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

| ツール | バージョン | 説明 |
| -------- | ---------- | ------ |
| Terraform | 1.9 | IaC ツール。Azureリソースを宣言的に定義・管理 |
| TFLint | latest | Terraformコードの静的解析ツール |
| Azure CLI | latest | AzureリソースをCLIから管理するツール |
| Git & Zsh | - | バージョン管理とシェル環境 |
| Docker-in-Docker | latest | コンテナ内でDockerを使用可能にする機能 |
| Node.js | LTS | JavaScript ランタイム |

#### 1.1.2 使用方法

**前提条件：**

- [Docker Desktop][docker-desktop] がインストール・起動されていること
- VS Code に [Dev Containers 拡張機能][devcontainers-ext] が
  インストールされていること

[docker-desktop]: https://www.docker.com/products/docker-desktop/
[devcontainers-ext]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

**Dev Containerで開く（Terraform 実行・本格開発）：**

1. VS Codeで **File > Open Folder**
2. リポジトリのルートフォルダを開く
3. Ctrl+Shift+P → 「**Dev Containers: Reopen in Container**」を選択
4. `Terraform Development` コンテナを選択
5. 必要なツールが自動的にセットアップされる（初回は数分かかる場合があります）

> :hourglass_flowing_sand: **初回起動時の注意**
>
> 初回はコンテナイメージのダウンロードとビルドが行われるため、5〜10分程度かかることがあります。
> 2回目以降はキャッシュが使用されるため、高速に起動します。

### 1.2. 通常の VS Code 環境で開く

このプロジェクト用に VS Code Workspace ファイルが用意されており、通常の VS Code 環境 (Dev Containerなし) で動作します。
VS Code のワークスペース機能は、複数プロジェクトの横断的な閲覧に便利となっています。
Terraform 実行には、手動でツールのインストールが必要です。

#### 1.2.1 インストールを推奨するツール

Dev Containerを使用しない場合は、以下のツールを手動でインストールしてください：

- [Terraform](https://www.terraform.io/downloads.html) >= 1.9
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [TFLint](https://github.com/terraform-linters/tflint)

推奨される VS Code 拡張機能（.vscode/extensions.jsonで自動推奨）：

- HashiCorp Terraform
- Azure Terraform
- Azure CLI Tools
- YAML

#### 1.2.2 使用方法

**VS Code Workspace ファイルで開く (コード閲覧・軽微な編集):**

1. リポジトリのルートにある `project-infra.code-workspace` を開く
2. `Foundry (Terraform IaC)` を選択する

## 2. プロジェクト構造

```text
basic/
├── main.*.tf          - リソース定義 (rg, keyvault, cognitive, search, vnet 等)
├── _variables.*.tf    - 変数定義 (foundry, keyvault, search, vnet)
├── _locals.*.tf       - ローカル変数 (命名規則)
├── data.tf            - データソース定義
├── backend.tf         - 状態管理のバックエンド用の設定
├── providers.tf       - プロバイダー設定
└── terraform.tf       - Terraformバージョン設定
```

## 3. IaC による Azure へのリソースの展開

### 3.1. Azure ログイン認証

Terraform の実行時、既定では Azure CLI のログイン認証済みのコンテキストを使用します。

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
現在は、以下のモジュールがあります

- [ベーシック](./basic/)

```bash
cd <project-root>/infra/terraform/basic
```

### 3.3 環境タイプの設定（本番環境 vs デモ環境）

展開する環境が本番環境かデモ環境かを指定できます。
この設定により、リソース削除時の動作が変わります。

#### デモ・開発環境の場合（既定）

既定では `is_production = false` となっており、以下の動作になります：

- **Key Vault**: `terraform destroy` 実行時に完全削除（パージ）され、即座に同じ名前で再作成可能
- **リソースグループ**: リソースが含まれていても削除可能

これにより、デモ環境を使い終わった後に完全にクリーンアップできます。

```bash
# 既定値を使用する場合は設定不要
terraform apply
```

#### 本番環境の場合

本番環境では、誤った削除からデータを保護するため、`is_production = true` を設定します：

- **Key Vault**: `terraform destroy` 実行時にソフト削除され、復旧期間中は回復可能
- **リソースグループ**: リソースが含まれている場合は削除を防止

```bash
# terraform.tfvars ファイルを作成
echo 'is_production = true' > terraform.tfvars

# または、コマンドラインで指定
terraform apply -var="is_production=true"
```

> :warning: **重要**
>
> 本番環境では必ず `is_production = true` を設定してください。
> これにより、Key Vault の誤削除時にもデータを回復できます。

### 3.4 バックエンド設定の準備

Terraform の状態ファイルを格納する Azure Storage アカウントの設定を準備します。
サンプルファイルをコピーして内容を変更してください。

```bash
cp ../backend.hcl.config.example backend.hcl
```

> :information_source: **backend.hcl の設定例**
>
> ```hcl
> storage_account_name = "<your-tfstate-storage-account>"
> container_name       = "tfstate"
> key                  = "basic-setup.terraform.tfstate"
> ```
>
> 必要に応じて、`resource_group_name` や `subscription_id` を指定することもできます
> （ストレージアカウントが別のサブスクリプションにある場合など）。

### 3.5. 初期化

```bash
terraform init -backend-config=backend.hcl
```

> :information_source: **`terraform init` とは？**
>
> このコマンドは Terraform プロジェクトを初期化します。
> 以下の処理が行われます：
>
> - 必要な Provider プラグインのダウンロード
> - バックエンド（状態ファイルの保存先）の設定
> - モジュールの初期化
>
> 新しい環境で初めて実行する場合や、
> Provider のバージョンを変更した場合に実行が必要です。

### 3.6. デプロイの事前確認

```bash
terraform plan
```

> :mag: **`terraform plan` とは？**
>
> このコマンドは、実際にリソースを変更せずに、
> 何が作成・変更・削除されるかをプレビューします。
> 出力の見方：
>
> - `+ create` : 新規作成されるリソース（緑色）
> - `~ update in-place` : 変更されるリソース（黄色）
> - `- destroy` : 削除されるリソース（赤色）
>
> **必ず `apply` 前に `plan` で変更内容を確認してください。**

### 3.7. デプロイ

```bash
terraform apply
```

実行すると、変更内容が表示され、確認プロンプトが表示されます。`yes` と入力して Enter を押すとデプロイが開始されます。

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

> :warning: **注意**
>
> デプロイには数分〜数十分かかる場合があります。プロセスを中断しないでください。
> 中断すると、リソースの状態が不整合になる可能性があります。

### 3.8. デプロイしたリソース削除

```bash
terraform apply -destroy
```

または、以下のショートカットコマンドでも同じ結果になります：

```bash
terraform destroy
```

> :rotating_light: **重要な警告**
>
> このコマンドは、Terraform で管理している
> すべてのリソースを**完全に削除**します。
>
> - 削除したリソースは復元できません
> - データベースなどのデータも失われます
> - 本番環境では特に慎重に実行してください
>
> 削除前に必ず `terraform plan -destroy` で削除対象を確認してください。

## 4. コード品質チェック

リポジトリへのコミットコマンドを実行すると、ステージ上のファイルに対して、コミット操作の前に、
`pre-commit` ツールを使って、このセクションで記されたチェックが実行されます。
手動で `pre-commit` ツールを実行するには、以下のコマンドを実行してください。

```bash
pre-commit run
```

### Terraform ファイルのフォーマットチェック

```bash
terraform fmt -recursive
```

### Terraform モジュールのバリデーションチェック

```bash
terraform validate
```

### TFLint による Linting

```bash
tflint
```

## 5. トラブルシューティング

### Dev Container が起動しない

**考えられる原因と対処法：**

| 原因 | 対処法 |
| ---- | ------ |
| Docker Desktop が停止 | Docker Desktop を起動し、ステータスバーが緑色になるまで待つ |
| WSL で Docker が未インストール | WSL 内で `docker --version` を実行して確認 |
| Dev Containers 拡張機能がない | VS Code の拡張機能からインストール |
| キャッシュの問題 | 「Dev Containers: Rebuild Container」を実行 |

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

### Terraform 状態ファイルのロックエラー

**エラー例：** `Error: Error acquiring the state lock`

前回の実行が正常に終了しなかった場合に発生します。

```bash
# ロックを強制解除（他の人が使用していないことを確認してから実行）
terraform force-unlock <LOCK_ID>
```

### Provider のバージョンエラー

**エラー例：** `Error: Incompatible provider version`

```bash
# プロバイダーキャッシュをクリアして再初期化
rm -rf .terraform
terraform init -backend-config=backend.hcl -upgrade
```

## 6. 用語集

初心者の方向けに、このドキュメントで使用される主な用語を説明します。

| 用語 | 説明 |
| ---- | ---- |
| **Terraform** | HashiCorp 社が開発した IaC ツール |
| **IaC** | インフラをコードとして管理する手法 |
| **Provider** | Terraform がクラウドサービスと連携するプラグイン |
| **State** | リソースの現在の状態を保存したファイル |
| **Backend** | 状態ファイルの保存先。チームではAzure Storageを使用 |
| **Module** | 再利用可能な Terraform コードの単位 |
| **Plan** | 変更内容をプレビューする操作 |
| **Apply** | Plan の変更を実際に適用する操作 |

## 7. 参考リンク

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [TFLint Rules](https://github.com/terraform-linters/tflint-ruleset-azurerm)
- [Terraform 公式チュートリアル](https://developer.hashicorp.com/terraform/tutorials)
- [Azure 初心者向けドキュメント](https://learn.microsoft.com/ja-jp/azure/)

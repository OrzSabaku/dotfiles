# dotfiles

シェル、エディタ、ターミナルの設定を `home/` 以下にホームディレクトリと同じ配置で管理します。

## 導入

```sh
python3 ~/dotfiles/install.py
```

既存の設定を初めて取り込む場合のみ、次を実行します。

```sh
python3 ~/dotfiles/install.py --import-existing
```

設定ファイルはリポジトリへのシンボリックリンクになります。内容が異なる既存ファイルや別のリンクがあると、変更せずに停止します。管理対象は `install.py` の `FILES` に明記されています。

新しい環境では、このリポジトリを `~/dotfiles` に置き、通常の導入コマンドを実行してください。`mise`、`starship`、`sheldon`、`fzf`、`zoxide` など、設定から呼ぶツールは別途インストールが必要です。`mise` のツール一覧は `home/.config/mise/config.toml` にあります。

認証情報、履歴、アプリのキャッシュや状態、個人用の Git identity は管理対象外です。公開前に差分を確認してください。

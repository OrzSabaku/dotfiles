# dotfiles

Fedora由来の設定を残しながら、OSごとの導入対象を明示して管理します。
`home/` は元の設定、`common/` は共通の個人設定、`profiles/` は環境固有の追加設定です。

## Omarchy

まずプレビューします。引数なしでは導入しません。

```sh
python3 ~/dotfiles/install.py --profile omarchy --dry-run
python3 ~/dotfiles/install.py --profile omarchy --apply
```

導入内容:

- Bash: 既存のOmarchy初期化を保持し、末尾から `common/bash.sh` を読み込みます。
  履歴・bat/fzf表示設定と `nvim-personal` 関数を追加します。miseなどの初期化は重複させません。
- Starship: `common/starship.toml` にリンクし、元のプロンプトを使用します。
- Ghostty: 既存のテーマ・フォント・シェル連携を保持し、末尾から個人設定を読み込みます。
  文字サイズ、透過、余白、分割キーなどを移します。外部シェーダーと旧環境の絶対パスは移しません。
- Neovim: 元の設定を `~/.config/nvim-personal/init.lua` にリンクします。
  通常の `nvim` は既存のLazyVimのままです。新しいBashで `nvim-personal`、
  または `NVIM_APPNAME=nvim-personal nvim` を実行すると個人設定を試せます。
  初回は設定内の `vim.pack.add()` によりプラグインを取得します。導入時には起動しません。

Vim設定、Zsh、Sheldon、デスクトップ設定は導入しません。
現在のmise設定も変更せず、ツールの追加・更新は行いません。
`home/.config/mise/config.toml` は元環境の一覧として残します。
基本CLIはOS側、言語ランタイムなどはmiseという分担を基本とし、必要なものを選んで追加してください。

### バックアップと復元

変更する既存ファイルは `~/.local/state/dotfiles/backups/<日時-ID>/` に保存します。
各導入で表示する復元コマンドを控えてください。

```sh
python3 ~/dotfiles/install.py --restore ~/.local/state/dotfiles/backups/<日時-ID>
python3 ~/dotfiles/install.py --restore ~/.local/state/dotfiles/backups/<日時-ID> --apply
```

復元も既定はプレビューです。導入後に変更された設定やリンク先は検出して停止します。
バックアップのチェックサムも検証します。復元後、空のディレクトリが残る場合があります。
設定は新しいシェルや端末から読み込まれます。起動中のアプリは自動再起動しません。

リンク先の個人設定を編集すると実環境にも反映されます。
一方、`.bashrc` とGhosttyのメイン設定はリンクにせず、Omarchy側で管理する部分を保ちます。
Omarchy更新などで個人設定の読み込み行が失われた場合は、プレビューを確認して再導入できます。

## Fedora

従来のインストーラーを明示的に選択します。Vimは対象外です。

```sh
python3 ~/dotfiles/install.py --profile fedora --apply
```

内容が異なる既存ファイルや別のリンクがあると、変更せず停止します。
初回に既存設定を取り込む場合だけ `--import-existing` を追加します。
この旧方式にはOmarchy版の自動バックアップ・復元機能はありません。

認証情報、履歴、キャッシュ、個人用Git identityは管理対象外です。

## Omarchy全体の設定の保存

個人設定を導入する前のユーザー設定56ファイルを `profiles/omarchy/snapshot/` にコピーして保存しています。
最初の導入前バックアップから再構成した状態です。実環境のファイルは置き換えていません。
保存コピーを編集しても実環境は変わりません。
設定の地図、読み込み順、比較・個別復元の手順は
[Omarchy設定ガイド](profiles/omarchy/README.md)を参照してください。

```sh
python3 ~/dotfiles/omarchy_snapshot.py
```

このコマンドは保存時点との差分を確認するだけで、設定を変更しません。

Gitタグ `omarchy-post-dotfiles-2026-10-18` が導入後、
`omarchy-pre-dotfiles-2026-10-18` が導入前の保存状態です。
現在の実環境は導入後なので、比較コマンドが差分を表示するのは正常です。

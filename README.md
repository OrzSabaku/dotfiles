# dotfiles

個人設定をGitで管理し、ファイル単位のシンボリックリンクで実環境から読み込みます。
過去の状態はコミットとタグに残します。

```text
common/                       共通のBash・Starship設定
profiles/omarchy/home/         Omarchyで現在使用する設定（ホームと同じ配置）
profiles/omarchy/files.json    導入対象とリンク先の明示的な一覧
home/                         Fedora由来の設定。Neovimのお試し設定もここを使用
install.py                    プレビュー・導入・バックアップからの復元
```

## Omarchy

```sh
python3 ~/dotfiles/install.py --profile omarchy --dry-run
python3 ~/dotfiles/install.py --profile omarchy --apply
```

59ファイルが対象です。現在のリンク先は `files.json` に記載しています。
既存ファイルと内容・権限が異なる場合や、無関係なリンクがある場合は変更前に停止します。
元の設定をバックアップした後、個々のファイルをリンクします。ディレクトリ全体はリンクしません。
新しいファイルは一覧に追加するまで導入しません。

Omarchy標準の読み込み、現在のテーマ連携、Bash、通常のNeovim（LazyVim）は維持しています。
`nvim-personal`ではFedora由来の個人設定を別途試せます。初回はプラグイン取得があります。
Vim・Zsh・Sheldonは導入しません。パッケージのインストールや更新も行いません。

設定の編集先、読み込み順、Gitでの比較、復元手順は
[Omarchy設定ガイド](profiles/omarchy/README.md)を参照してください。

## Gitとバックアップ

```sh
cd ~/dotfiles
git diff
git add <変更したファイル>
git commit -m '変更内容'
```

リンク先を編集すると実環境にも反映されます。過去の内容を見るだけなら `git show` を使います。
`git switch`や`git restore`でファイルを書き換えると、実環境の設定も変わります。
自動再読み込みのある設定は保存時点で適用されます。

導入処理のバックアップは `~/.local/state/dotfiles/backups/<日時-ID>/` に保存します。

```sh
python3 ~/dotfiles/install.py --restore <バックアップディレクトリ>
python3 ~/dotfiles/install.py --restore <バックアップディレクトリ> --apply
```

復元も既定はプレビューです。導入後に内容が変わった場合は停止します。
今回のリンク化直前のバックアップは `20261018-022009-83b032bf` です。

| タグ | 状態 |
|---|---|
| `omarchy-post-dotfiles-2026-10-18` | 最初の個人設定導入後の保存コピー |
| `omarchy-pre-dotfiles-2026-10-18` | 個人設定導入前を再構成した保存コピー |
| `omarchy-linked-dotfiles-2026-10-18` | 現在の設定を実環境からリンクする運用へ移行 |

旧`snapshot/`と専用比較スクリプトは廃止しました。以前の状態はタグから確認できます。
認証情報・履歴・キャッシュ・個人用Git identity・生成テーマは対象外です。
リモートへの送信は行っていません。

## Fedora

```sh
python3 ~/dotfiles/install.py --profile fedora --apply
```

従来の`home/`を使用します（Vimは対象外）。異なる既存ファイルがある場合は停止します。
初回に既存設定を取り込む場合だけ `--import-existing` を追加します。
この旧方式にはOmarchy版の自動バックアップ・復元機能はありません。

## 検証

```sh
python3 -m unittest discover -s ~/dotfiles/tests -v
```

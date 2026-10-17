# dotfiles

設定は「共通」「Omarchy」「Fedora」に分け、各ディレクトリ内をホームディレクトリと同じ配置にします。

```text
common/             OSをまたいで使う設定
  .config/
    dotfiles/bash.sh
    starship.toml
    nvim/init.lua
omarchy/            Omarchy固有の設定
  .bashrc
  .bash_profile
  .config/
  files.json        導入対象とリンク先の対応表
  README.md         設定地図と運用方法
fedora/             Fedora固有の設定
  .bashrc
  .zshrc
  .config/
  README.md
scripts/            導入・復元処理
tests/             安全機構のテスト
install.py          全環境共通の入口
```

Omarchyは`common/`と`omarchy/`、Fedoraは`common/`と`fedora/`から必要な設定を使用します。
各OSへcommonを丸ごと導入するわけではありません。導入するファイルを明示的に選択します。

## 導入

```sh
python3 ~/dotfiles/install.py --profile omarchy --dry-run
python3 ~/dotfiles/install.py --profile omarchy --apply
```

Omarchyの対象は59ファイルです。内容・権限が異なる既存ファイルや、無関係なリンクがあれば停止します。
既存設定をバックアップした後、ファイル単位でリンクします。ディレクトリ全体はリンクしません。
詳しくは[Omarchyの設定地図](omarchy/README.md)を参照してください。

Fedoraは従来の方式です。[Fedoraの説明](fedora/README.md)も確認してください。

```sh
python3 ~/dotfiles/install.py --profile fedora --apply
```

Vim設定は保存されていますが導入対象外です。パッケージの導入・更新は行いません。
認証情報・履歴・キャッシュ・個人用Git identity・生成テーマは対象外です。

## 変更と履歴

リンク先の編集は実環境に反映されます。`git diff`で変更を確認してコミットします。
過去の内容を確認するだけなら`git show`を使ってください。
`git switch`や`git restore`は実環境の設定も変更します。

| タグ | 状態 |
|---|---|
| `omarchy-post-dotfiles-2026-10-18` | 最初の個人設定導入後の保存コピー |
| `omarchy-pre-dotfiles-2026-10-18` | 個人設定導入前を再構成した保存コピー |
| `omarchy-linked-dotfiles-2026-10-18` | ファイル単位のリンク運用へ移行 |
| `dotfiles-layout-2026-10-18` | common・omarchy・fedoraの配置へ整理 |

過去のタグには当時のパスでファイルが保存されています。現在のパスとは異なる場合があります。
リモートへの送信は行っていません。

## 復元と検証

```sh
python3 ~/dotfiles/install.py --restore <バックアップディレクトリ>
python3 ~/dotfiles/install.py --restore <バックアップディレクトリ> --apply
python3 -m unittest discover -s ~/dotfiles/tests -v
```

復元は既定ではプレビューです。導入後に内容が変わった場合は停止します。
バックアップは`~/.local/state/dotfiles/backups/`に保存します。

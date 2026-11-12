# dotfiles

<!--toc:start-->
- [dotfiles](#dotfiles)
  - [構成](#構成)
  - [導入](#導入)
  - [覚えておくこと](#覚えておくこと)
  - [メモ](#メモ)
<!--toc:end-->

FedoraとOmarchyで使う個人設定。シェルやエディタの操作を揃えています。

普段はOmarchy・Zsh・Ghostty・Neovim（LazyVim）の組み合わせです。

## 構成

- `common/` — OSに依存しない設定
- `omarchy/`・`fedora/` — OS固有の初期化やデスクトップ連携
- `experiments/` — 明示的に起動する実験用設定
- `scripts/`・`tests/` — 導入・復元と、その検証

設定はホームと同じ配置で保存し、ファイル単位でリンクします。
導入対象は[Omarchyの一覧](omarchy/files.json)と[Fedoraのスクリプト](scripts/install_fedora.py)で選びます。

## 導入

`~/dotfiles`に置いたリポジトリで実行します。GitとPython 3が必要です。

```sh
cd ~/dotfiles
git submodule update --init --recursive
python3 install.py --profile omarchy --dry-run
python3 install.py --profile omarchy --apply
```

Omarchyでは既存設定をバックアップし、内容・権限が違うファイルや無関係なリンクがあれば停止します。
Zshの初回導入は通常の端末で `scripts/setup-zsh` を実行します。
Fedoraは[こちら](fedora/README.md)。

## 覚えておくこと

- リンク先の編集は実環境にも反映されます。過去を見るだけなら `git show` を使います。
- Zshプラグインの変更後は `scripts/update-zsh-plugins` を実行し、新しい端末を開きます。
- Gitの名前・メール・署名鍵は `~/.config/git/config.private` へ。`git config --global` は共有原本を書き換えます。
- Omarchyのバックアップは `~/.local/state/dotfiles/backups/`。復元も既定はプレビューです。

```sh
python3 install.py --restore <バックアップディレクトリ>
python3 install.py --restore <バックアップディレクトリ> --apply
```

## メモ

[Omarchy](omarchy/README.md) · [Fedora](fedora/README.md) · [Neovimの実験](experiments/README.md)

詳しい手順は[GitHub Wiki](https://github.com/OrzSabaku/dotfiles/wiki)へ。

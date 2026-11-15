# dotfiles

FedoraとOmarchyで使う個人設定。chezmoiで管理します。
普段はOmarchy・Zsh・Ghostty・Neovim（LazyVim）の組み合わせです。

## 導入

Git・chezmoiが必要です。管理元は既定の `~/.local/share/chezmoi` です。

```sh
chezmoi init OrzSabaku
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
```

`init`で環境（`omarchy` / `fedora`）とZsh・Neovim・Ghostty・Fcitx5の管理有無を選びます。
選択はローカルの `~/.config/chezmoi/chezmoi.toml` に保存します。変更は `chezmoi init --prompt`。
パッケージ導入・miseツール更新・ログインシェル変更は自動実行しません。
OmarchyでZshを初めて導入するときは、通常の端末で `scripts/setup-zsh` を実行します。

## 普段の操作

```sh
chezmoi edit ~/.config/starship.toml
chezmoi diff
chezmoi apply
```

- 原本の変更は `apply` するまで実環境に反映されません。
- アプリや実ファイル側で変更した設定は差分を確認し、通常ファイルなら `chezmoi re-add <パス>` で取り込みます。
  OS別テンプレートの設定は `home/.chezmoitemplates/<環境>/` の該当ファイルへ反映します。
- Zshプラグインは設定適用後に `scripts/update-zsh-plugins` を実行し、新しい端末を開きます。
- Gitの名前・メール・署名鍵は非管理の `~/.config/git/config.private` へ。
  [記入例](examples/git/config.private.example)を参照し、権限は `600` にします。
- Git操作で原本が変わったら `chezmoi diff` → `chezmoi apply`。リモート送信は手動です。

## 構成

- `home/` — chezmoiの管理対象。`dot_`は先頭の`.`、`private_`は非公開権限、`executable_`は実行権限。
- `home/.chezmoitemplates/` — OS別の初期化・アプリ設定。共通設定は `home/dot_config/` に1か所で保存。
- `home/.chezmoiignore` — 環境・アプリごとの配置対象の選択。
- `scripts/`・`tests/` — 明示的なセットアップと仮ホームでの検証。
- `experiments/` — [Neovimなどの実験](experiments/README.md)。通常の導入には含めません。

旧方式のバックアップは `~/.local/state/dotfiles/backups/` に残します。
読み出しは `python3 scripts/restore-legacy.py <バックアップディレクトリ>`、適用には `--apply` が必要です。
復元後はchezmoiの原本との差分が生じます。

詳しいメモは [Omarchy](docs/omarchy.md) と [GitHub Wiki](https://github.com/OrzSabaku/dotfiles/wiki)へ。

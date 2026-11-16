# dotfiles

FedoraとOmarchyで使う個人設定。chezmoiで管理します。
普段はOmarchy・Zsh・Ghostty・Neovim（LazyVim）を使います。

## 導入

Git・chezmoiが必要です。管理元は既定の `~/.local/share/chezmoi` です。

```sh
chezmoi init OrzSabaku
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
```

`init`で環境（`omarchy` / `fedora`）と管理するアプリを選びます。
選択は `~/.config/chezmoi/chezmoi.toml` に保存されます。選び直す場合は `chezmoi init --prompt`。
パッケージ導入・ツール更新・ログインシェル変更は自動実行しません。

## 普段の操作

```sh
chezmoi edit ~/.config/starship.toml
chezmoi diff
chezmoi apply
```

- 原本の変更は `apply` で反映します。管理元で作業するときは `chezmoi cd`。
- 実ファイル側の変更は差分を確認してから取り込みます。通常ファイルは `chezmoi re-add <パス>`、
  OS別テンプレートは `home/.chezmoitemplates/<環境>/` の該当ファイルを編集します。
- Gitの名前・メール・署名鍵は非管理の `~/.config/git/config.private` へ。
  [記入例](examples/git/config.private.example)を参照し、権限は `600` にします。
- Gitで原本を戻した場合も、反映前に `chezmoi diff` を確認します。リモート送信は手動です。

## 管理元で使うスクリプト

Rubyが必要です（追加gemは不要）。`chezmoi cd` で移動してから実行します。

- `scripts/setup-zsh.rb` — OmarchyでのZsh初回導入。通常の端末で実行します。
- `scripts/update-zsh-plugins.rb` — Sheldon設定の適用後にプラグインを取得・検証し、キャッシュを切り替えます。完了後に新しい端末を開きます。
- `scripts/nvim-experiment.rb` — [実験用Neovim](experiments/README.md)を起動します。

## 構成

`home/` がchezmoiの管理対象です。共通設定は `home/dot_config/`、OS別の内容は
`home/.chezmoitemplates/` に保存し、`home/.chezmoiignore` で配置対象を選びます。
`experiments/` は通常の導入には含めません。

開発・テストとLinux x86_64用バイナリの配布手順は [Rubyスクリプトの開発](https://github.com/OrzSabaku/dotfiles/wiki/Ruby-Development)を参照してください。

補足は [Omarchy](https://github.com/OrzSabaku/dotfiles/wiki/Omarchy) と [GitHub Wiki](https://github.com/OrzSabaku/dotfiles/wiki)へ。

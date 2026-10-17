# Omarchyの設定地図

このディレクトリはOmarchy固有の設定です。`.config/`などホームと同じ配置にしています。
OS共通の設定は`../common/`にあり、導入する59ファイルの対応は`files.json`で管理します。

```text
~/.config/hypr/input.lua → ~/dotfiles/omarchy/.config/hypr/input.lua
~/.config/starship.toml  → ~/dotfiles/common/.config/starship.toml
```

## 編集先

| 目的 | このディレクトリからのパス |
|---|---|
| デスクトップの読み込み順 | `.config/hypr/hyprland.lua` |
| ディスプレイ・倍率 | `.config/hypr/monitors.lua` |
| キーボード・マウス | `.config/hypr/input.lua` |
| ショートカット | `.config/hypr/bindings.lua` |
| 枠・余白・アニメーション | `.config/hypr/looknfeel.lua` |
| 自動起動 | `.config/hypr/autostart.lua` |
| ナイトライト・画面共有 | `.config/hypr/hyprsunset.conf`、`.config/hypr/xdph.conf` |
| バー・アイドル時間など | `.config/omarchy/shell.json` |
| シェルのフォント補足 | `.config/omarchy/shell.toml` |
| メニュー・フック | `.config/omarchy/extensions/`、`.config/omarchy/hooks/` |
| テーマ生成テンプレート | `.config/omarchy/themed/` |
| GhosttyのOmarchy連携・個人設定 | `.config/ghostty/config`、`.config/ghostty/dotfiles.conf` |
| その他の端末 | `.config/alacritty/`、`.config/foot/`、`.config/kitty/` |
| BashのOmarchy連携 | `.bashrc`、`.bash_profile` |
| Bashの個人設定 | `../common/.config/dotfiles/bash.sh` |
| プロンプト | `../common/.config/starship.toml` |
| 通常のNeovim（LazyVim） | `.config/nvim/lua/config/`、`.config/nvim/lua/plugins/` |
| お試しNeovim（nvim-personal） | `../common/.config/nvim/init.lua` |
| mise | `.config/mise/config.toml` |
| tmux・btop・lazygit | `.config/tmux/`、`.config/btop/`、`.config/lazygit/` |
| フォント代替 | `.config/fontconfig/fonts.conf` |

## 読み込み順

```text
Hyprland: Omarchy標準 → ~/.config/hypr/ の個人設定
Bash:     ~/.bashrc → Omarchy標準 → commonのbash.sh
Ghostty:  現在のテーマ → config → dotfiles.conf
Starship: Bashが起動 → commonのstarship.toml
Neovim:   nvimはLazyVim / nvim-personalは共通の個人設定
```

Omarchy本体の`/usr/share/omarchy/`や生成状態の`~/.local/state/omarchy/`は変更しません。
btopとNeovimの生成テーマリンクもそのまま残しています。
フックの`.sample`は例です。ディレクトリや生成ファイルを自動でGit管理には取り込みません。

## 編集後の確認

- Bashは新しいシェルで確認します。
- HyprlandのLuaは保存時に再読み込みされます。編集後は`hyprctl reload`と`hyprctl configerrors`で確認します。
- シェル設定にも自動再読み込みがあります。
- Ghosttyは`ghostty +validate-config`で検証します。
- ナイトライトや画面共有は別プロセスなので、Hyprlandの再読み込みだけでは反映されません。

今回の配置変更では59ファイルの内容・権限を維持しています。
Hyprlandのソケットにはエージェントから接続できないため、実行中のコンポジターでの確認はできていません。

アプリがリンクを通常ファイルへ置き換えた場合は、次のプレビューで確認できます。

```sh
python3 ~/dotfiles/install.py --profile omarchy --dry-run
```

内容が違う場合は停止します。差分を確認し、必要な内容をリポジトリへ反映してから再導入します。

## 今回の配置変更を取り消す

```sh
python3 ~/dotfiles/install.py --restore ~/.local/state/dotfiles/backups/20261018-024831-cc8aa2f5
python3 ~/dotfiles/install.py --restore ~/.local/state/dotfiles/backups/20261018-024831-cc8aa2f5 --apply
```

既定はプレビューです。導入後に編集された設定は上書きせず停止します。
移動済みで旧リンク先が存在しない場合は、壊れたリンクではなくバックアップの内容を通常ファイルとして戻します。
したがって復元後は設定内容が保たれ、dotfilesへのリンクは解除されます。
Gitの過去タグを見るだけなら`git show`を使い、作業ツリー全体を切り替えないでください。

これは設定ファイルの管理です。OS・パッケージ・プラグイン・壁紙画像の全体バックアップではありません。

# Omarchyの設定地図

## 管理の構造

`home/`は現在有効なOmarchy固有の設定です。ホームディレクトリからファイル単位でリンクしています。
共通のBash・Starshipとお試しNeovimは、それぞれリポジトリの`common/`、`home/`を参照します。
59ファイルの対応表は`files.json`にあります。固定チェックサムは使わず、変更履歴をGitで管理します。

```text
~/.config/hypr/input.lua
    → ~/dotfiles/profiles/omarchy/home/.config/hypr/input.lua
~/.config/starship.toml
    → ~/dotfiles/common/starship.toml
```

Omarchy本体の`/usr/share/omarchy/`、生成状態の`~/.local/state/omarchy/`は対象外です。
ディレクトリはリンクしないため、アプリが新しいファイルを作っても自動では管理対象になりません。
Git identity、認証情報、履歴、キャッシュ、ブラウザー、壁紙画像は管理していません。
空のディレクトリも保存しません。

## 変更したいときの編集先

以下はリポジトリからの相対パスです。
`home/.config/`は、このガイドがある`profiles/omarchy/`内のものです。

| 変更したいもの | 編集先 |
|---|---|
| デスクトップの読み込み順 | `home/.config/hypr/hyprland.lua` |
| ディスプレイ・倍率 | `home/.config/hypr/monitors.lua` |
| キーボード・マウス | `home/.config/hypr/input.lua` |
| ショートカット | `home/.config/hypr/bindings.lua` |
| 枠・余白・アニメーション | `home/.config/hypr/looknfeel.lua` |
| 自動起動 | `home/.config/hypr/autostart.lua` |
| ナイトライト | `home/.config/hypr/hyprsunset.conf` |
| 画面共有ポータル | `home/.config/hypr/xdph.conf` |
| バー・アイドル時間など | `home/.config/omarchy/shell.json` |
| シェルのフォント補足設定 | `home/.config/omarchy/shell.toml` |
| メニュー | `home/.config/omarchy/extensions/omarchy-menu.jsonc` |
| イベント時の処理 | `home/.config/omarchy/hooks/`（`.sample`は例） |
| テーマ生成テンプレート | `home/.config/omarchy/themed/` |
| GhosttyのOmarchy連携 | `home/.config/ghostty/config` |
| Ghosttyの個人設定 | `home/.config/ghostty/dotfiles.conf` |
| Alacritty・Foot・Kitty | `home/.config/alacritty/`、`home/.config/foot/`、`home/.config/kitty/` |
| BashのOmarchy連携 | `home/.bashrc`、`home/.bash_profile` |
| Bashの個人設定 | リポジトリ直下の`common/bash.sh` |
| プロンプト | リポジトリ直下の`common/starship.toml` |
| 通常のNeovim（LazyVim） | `home/.config/nvim/lua/config/`、`home/.config/nvim/lua/plugins/` |
| お試しNeovim（`nvim-personal`） | リポジトリ直下の`home/.config/nvim/init.lua` |
| mise | `home/.config/mise/config.toml` |
| tmux | `home/.config/tmux/tmux.conf` |
| btop・lazygit | `home/.config/btop/btop.conf`、`home/.config/lazygit/config.yml` |
| フォント代替 | `home/.config/fontconfig/fonts.conf` |

旧`profiles/omarchy/ghostty.conf`は、新しい個人設定への互換リンクとして残しています。
以前のバックアップからリンクを復元しても参照できるようにするためです。

## 読み込み順と反映

```text
Hyprland: Omarchy標準 → ~/.config/hypr/ の個人設定
Bash:     ~/.bashrc → Omarchy標準 → common/bash.sh
Ghostty:  現在のテーマ → configの設定 → dotfiles.conf
Starship: Bashが起動 → common/starship.toml
Neovim:   nvimはLazyVim / nvim-personalは独立した設定
```

- Bashは新しいシェルで確認します。
- HyprlandのLuaは保存時に再読み込みされます。編集後は `hyprctl reload` と `hyprctl configerrors` で確認します。
- `shell.json`やシェルのプラグインにも自動再読み込みがあります。
- Ghosttyは `ghostty +validate-config` で検証し、新しいウィンドウなどで反映を確認します。
- ナイトライトや画面共有は別プロセスの設定です。Hyprlandの再読み込みだけでは反映されません。

リンク化時には59ファイルの内容・権限が移行前と一致することを確認しています。
Bashの起動とGhosttyの検証は通りました。Hyprlandはエージェントからのソケット接続が
`Couldn't set socket timeout (2)`で失敗し、実行中のコンポジターでの再読み込み確認はできていません。
設定内容は変更していません。

## 日々の運用

編集後は`git diff`で確認してコミットします。過去のファイルを見るだけなら次を使います。

```sh
git show omarchy-linked-dotfiles-2026-10-18:profiles/omarchy/home/.config/hypr/input.lua
```

以前の導入前タグでは配置が異なります。

```sh
git show omarchy-pre-dotfiles-2026-10-18:profiles/omarchy/snapshot/home/.bashrc
```

`git switch`・`git restore`は実際の設定も書き換えるため、過去を見る目的には使わないでください。
設定を戻す場合は対象ファイルを選び、現在の内容を保存してから行います。

アプリやOmarchyのコマンドが設定を書き換えると、Git差分に出たり、リンクが通常ファイルへ
置き換わったりする場合があります。導入プレビューでリンクを確認できます。

```sh
python3 ~/dotfiles/install.py --profile omarchy --dry-run
```

内容が異なる既存ファイルは上書きせず停止します。差分を確認し、必要な内容を
リポジトリへ反映してから再導入します。自動取り込み・強制上書きは行いません。
新しい設定を管理したい場合は、認証情報などがないことを確認してコピーし、`files.json`に追加します。

## 今回のリンク化を取り消す

```sh
python3 ~/dotfiles/install.py --restore ~/.local/state/dotfiles/backups/20261018-022009-83b032bf
python3 ~/dotfiles/install.py --restore ~/.local/state/dotfiles/backups/20261018-022009-83b032bf --apply
```

最初のコマンドはプレビューです。リンク化後に内容が変更されていると停止します。
このバックアップはリンク化だけを取り消します。以前から使っていた3本の個人設定リンクは残ります。
最初の個人設定導入前まで戻す操作は、別のバックアップ`20261018-013918-7674d885`を使います。
アプリの再起動は行いません。復元により設定が自動再読み込みされる場合があります。

Gitタグは履歴の保存、ローカルバックアップは導入操作の取り消しを担います。
パッケージやプラグインまで再現するOS全体のバックアップではありません。

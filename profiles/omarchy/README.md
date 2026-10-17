# このOmarchy環境の設定地図

## 今回保存したもの

`snapshot/home/` は2026-10-18時点のユーザー設定のコピーです。
実際に動いている設定へのリンクではありません。**このコピーを編集しても実環境は変わりません。**
復元元として保持するため、コピーと `snapshot/manifest.json` は直接編集しないでください。
manifestには59ファイルのパス、チェックサム、モード、取得日時、主要パッケージのバージョン、テーマ名があります。

標準の参照先は引き続き `/usr/share/omarchy/` です。その本体はコピーしていません。
この保存はユーザー設定の復元用であり、OS・パッケージ・プラグイン・壁紙画像まで再現するバックアップではありません。
別OSにこのスナップショットを一括導入する用途には使いません。

## 何を変えたいとき、どこを編集するか

以下はホームディレクトリからの相対パスです。

| 変更したいもの | 実際に有効な設定 |
|---|---|
| デスクトップ全体の読み込み順 | `.config/hypr/hyprland.lua` |
| ディスプレイ・倍率 | `.config/hypr/monitors.lua` |
| キーボード・マウス | `.config/hypr/input.lua` |
| デスクトップのキー割り当て | `.config/hypr/bindings.lua` |
| 枠・余白・アニメーション | `.config/hypr/looknfeel.lua` |
| 自動起動 | `.config/hypr/autostart.lua` |
| ナイトライト | `.config/hypr/hyprsunset.conf` |
| 画面共有ポータル | `.config/hypr/xdph.conf` |
| バー・通知などのシェル設定、アイドル時間 | `.config/omarchy/shell.json` |
| シェルのフォント補足設定 | `.config/omarchy/shell.toml` |
| メニュー | `.config/omarchy/extensions/omarchy-menu.jsonc` |
| イベント時の処理 | `.config/omarchy/hooks/`（`.sample`は例） |
| 個人テーマ・テーマ生成テンプレート | `.config/omarchy/themes/`、`.config/omarchy/themed/` |
| Alacritty・Foot・Kitty | `.config/alacritty/alacritty.toml`、`.config/foot/foot.ini`、`.config/kitty/kitty.conf` |
| GhosttyのOmarchy連携 | `.config/ghostty/config` |
| Ghosttyの個人設定 | `~/dotfiles/profiles/omarchy/ghostty.conf` |
| BashのOmarchy連携 | `.bashrc`（ログイン時は `.bash_profile` 経由） |
| Bashの個人設定 | `~/dotfiles/common/bash.sh` |
| プロンプト | `~/dotfiles/common/starship.toml` |
| 通常のNeovim（LazyVim） | `.config/nvim/lua/config/`、`.config/nvim/lua/plugins/` |
| お試しNeovim（`nvim-personal`） | `~/dotfiles/home/.config/nvim/init.lua` |
| mise | `.config/mise/config.toml` |
| tmux | `.config/tmux/tmux.conf` |
| btop・lazygit | `.config/btop/btop.conf`、`.config/lazygit/config.yml` |
| 日本語などのフォント代替 | `.config/fontconfig/fonts.conf` |

`~/.config/omarchy/`配下のbranding、defaults、フックやテンプレートのサンプルも保存しています。
現在の`themes/`、`plugins/`など空のディレクトリはファイル一覧には含まれません。
Git identity・認証情報・履歴・ブラウザー・キャッシュは対象外です。
現在のテーマから生成されるbtop/Neovimのリンクも対象外です。
テーマ名は `tokyo-night` として記録しました。テーマの切り替えはOmarchyのテーマ操作を使用します。

## 設定の読み込み順

```text
Hyprland: Omarchy標準 → ~/.config/hypr/ の個人設定
Bash:     ~/.bashrc → Omarchy標準 → dotfiles/common/bash.sh
Ghostty:  現在のテーマ → configの設定 → dotfiles/profiles/omarchy/ghostty.conf
Starship: Bashが起動 → ~/.config/starship.toml → dotfiles/common/starship.toml
Neovim:   nvimはLazyVim / nvim-personalは独立した設定
```

今回の保存ではこれらの読み込み順は変更していません。
`install.py --profile omarchy`は以前追加した個人設定の導入用です。
このスナップショット一式をリンクするコマンドではありません。

## 保存時点との差分を見る

```sh
python3 ~/dotfiles/omarchy_snapshot.py
python3 ~/dotfiles/omarchy_snapshot.py --diff --file .config/hypr/input.lua
```

既定の動作は読み取りのみです。一致なら終了コード0、差分があれば1です。
比較は保存済み59ファイルに限ります。保存後に追加した新しいファイルの検出・取り込みは行いません。
スナップショット自体が編集されると、チェックサム検証で停止します。

## ファイルを指定して戻す

まずプレビューします。

```sh
python3 ~/dotfiles/omarchy_snapshot.py --restore --file .config/hypr/input.lua --diff
```

実際に戻すには `--apply` を付けます。

```sh
python3 ~/dotfiles/omarchy_snapshot.py --restore --file .config/hypr/input.lua --apply
```

- 復元対象は `--file` で明示します。複数の場合は繰り返し指定します。
- 復元前のファイルを `~/.local/state/dotfiles/backups/snapshot-restore-<日時-ID>/` に保存します。
- その復元操作を取り消す場合は、表示されたバックアップを `install.py --restore <バックアップ> --apply` で戻せます。
- リンクされた個人設定は、自動復元せず停止します。表のリンク先を確認して編集してください。
- アプリは再起動しません。ただしHyprlandやシェル設定には自動再読み込みがあります。
- HyprlandのLuaを戻した後は `hyprctl reload` と `hyprctl configerrors` で確認します。

`install.py --restore`で以前の導入を取り消す操作と、今回の保存時点へ戻す操作は別です。
今回の保存時点は、以前の個人設定を導入した後の状態です。

## これからの運用

当面は実環境の設定を編集し、このスナップショットとの差分を確認します。
保存していない状態からの編集を避け、変更前に対象ファイルを別名でバックアップしてください。
落ち着いた設定から、個人用の管理ファイルへ段階的に移します。
このベースラインを更新する自動上書き機能は設けていません。

Gitの履歴にはまだコミットしていません。ファイルはローカルリポジトリ内に保存済みです。
公開・リモート送信は行っていません。

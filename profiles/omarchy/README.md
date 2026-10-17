# このOmarchy環境の設定地図

## 今回保存したもの

`snapshot/home/` は2026-10-18の個人設定導入直前のユーザー設定を再構成したコピーです。
先に保存した導入後の状態へ、最初のバックアップに記録された変更前の内容を適用しました。
既存のカスタマイズも含むため、Omarchyの工場出荷状態ではありません。
実際に動いている設定へのリンクではありません。**このコピーを編集しても実環境は変わりません。**
復元元として保持するため、コピーと `snapshot/manifest.json` は直接編集しないでください。
manifestには56ファイルのパス、チェックサム、モード、取得日時、主要パッケージのバージョン、テーマ名があります。
導入前には存在しなかった3ファイルと、再構成元のコミット・バックアップも記録しています。
`captured_at`とバージョン情報は元の導入後スナップショットの取得時点、
`reconstruction.reconstructed_at`は導入前への再構成日時です。

標準の参照先は引き続き `/usr/share/omarchy/` です。その本体はコピーしていません。
この保存はユーザー設定の復元用であり、OS・パッケージ・プラグイン・壁紙画像まで再現するバックアップではありません。
別OSにこのスナップショットを一括導入する用途には使いません。

## 何を変えたいとき、どこを編集するか

この表は現在の実環境（個人設定導入後）の編集先です。
`bash.sh`、Ghosttyの`dotfiles.conf`、`nvim-personal`は導入前スナップショットにはありません。

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
比較は保存済み56ファイルと、導入前には存在しなかった3ファイルに限ります。
現在の実環境は導入後なので、3ファイルの`CHANGED`と3ファイルの`ADDED`が表示されるのは正常です。
それ以外の新しいファイルの検出・取り込みは行いません。
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
現在の保存内容は個人設定導入前です。比較結果の`ADDED`ファイルはこのツールでは削除しません。
導入一式を取り消す場合は、最初の導入バックアップと`install.py --restore`を使用します。

## これからの運用

当面は実環境の設定を編集し、このスナップショットとの差分を確認します。
保存していない状態からの編集を避け、変更前に対象ファイルを別名でバックアップしてください。
落ち着いた設定から、個人用の管理ファイルへ段階的に移します。
このベースラインを更新する自動上書き機能は設けていません。

Gitには次の2つの状態をコミット・タグ付けしています。

| タグ | 保存状態 |
|---|---|
| `omarchy-post-dotfiles-2026-10-18` | 個人設定導入後（最初に保存した59ファイル） |
| `omarchy-pre-dotfiles-2026-10-18` | 個人設定導入前（56ファイルと3ファイルの不在記録） |

両方の差分は、リポジトリ内で次のように確認できます。

```sh
git diff omarchy-pre-dotfiles-2026-10-18 omarchy-post-dotfiles-2026-10-18 -- profiles/omarchy/snapshot/
```

実環境がdotfiles内のファイルを参照しているため、過去の状態を見るだけなら
`git show <タグ>:<パス>`を使い、作業ツリー全体の切り替えは避けてください。
公開・リモート送信は行っていません。

# Omarchyの設定地図

このディレクトリはOmarchy固有の設定です。`.config/`などホームと同じ配置にしています。
OS共通の設定は`../common/`にあり、導入する63ファイルの対応は`files.json`で管理します。

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
| GhosttyのOmarchy連携 | `.config/ghostty/config` |
| Ghosttyの共通操作設定 | `../common/.config/ghostty/dotfiles.conf` |
| その他の端末 | `.config/alacritty/`、`.config/foot/`、`.config/kitty/` |
| BashのOmarchy連携 | `.bashrc`、`.bash_profile` |
| Bashの個人設定 | `../common/.config/dotfiles/bash.sh` |
| Bash/Zsh共通の環境・表示設定 | `../common/.config/dotfiles/env.sh` |
| プロンプト | `../common/.config/starship.toml` |
| 共通のメインNeovim（LazyVim） | `../common/.config/nvim/` |
| OmarchyのNeovimテーマ連携 | `.config/nvim/lua/omarchy/plugins/` |
| 自作設定の実験 | `../experiments/nvim-experiment/init.lua`（通常導入対象外） |
| mise | `.config/mise/config.toml` |
| tmux・btop・lazygit | `.config/tmux/`、`.config/btop/`、`.config/lazygit/` |
| フォント代替 | `.config/fontconfig/fonts.conf` |

## 読み込み順

```text
Hyprland: Omarchy標準 → ~/.config/hypr/ の個人設定
Bash:     ~/.bashrc → Omarchy標準 → commonのbash.sh
Ghostty:  現在のテーマ → config → dotfiles.conf
Starship: Bashが起動 → commonのstarship.toml
Neovim:   共通のLazyVim → 存在する場合だけOmarchyテーマ追加設定
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

前回の配置変更では59ファイルの内容・権限を維持しました。
その後、メインのNeovimを共通化し、実験用の1ファイルを導入対象から除いて58ファイルになっています。
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

## Neovim共通化時のバックアップ

2026-10-18の共通化前の状態はGitタグ`dotfiles-layout-2026-10-18`にあります。
リンク移行前のバックアップは`~/.local/state/dotfiles/backups/20261018-030634-842018b1/`、
削除した旧テーマ読み込みリンクと実験リンクの内容は
`~/.local/state/dotfiles/backups/neovim-retired-20261018-030633/`に保存しました。
移行後に共通設定の読み込み処理も更新しているため、リンク移行のバックアップを
そのまま一括適用する操作は変更検出で停止する場合があります。
戻す際はGit差分を確認して対象を選び、現在の変更を保存してから行います。
共通設定単独・Omarchy追加設定ありの両方でヘッドレス起動を確認しています。

## シェル・Ghostty共通化

`env.sh`の追加で管理対象は59ファイルになりました。Omarchy標準のBash初期化はそのままです。
当時はZshとSheldonをこのOSへ導入していませんでした。現在は以下の専用手順で導入する構成です。
Ghosttyの個人設定を共通側へ移した際のバックアップは
`~/.local/state/dotfiles/backups/20261018-030904-9d12b6e5/`です。
共通Bashの内容の変更前はGitタグ`nvim-common-2026-10-18`で確認できます。
Bashの起動・Ghosttyの検証と、仮ホームでのFedora導入を確認しました。
Zsh本体が未導入のため、Zshの実起動は未確認です。

## Zsh

通常のユーザー端末から`~/dotfiles/scripts/setup-zsh`を実行します。
パッケージ導入から起動検証まで成功した後にだけ、ログインシェルをZshに変更します。
Bashの設定は残り、`bash`で起動できます。ログインシェルを戻す場合は`chsh -s /usr/bin/bash`です。

```text
~/.zshenv → Omarchyのenv-bootstrap（PATH、mise shims）
~/.zshrc  → Omarchyのenvs・aliases → 共通zsh.zsh
                                     ├─ env.sh
                                     ├─ 補完・履歴・キー操作
                                     └─ mise・Starship・zoxide・fzf・Sheldon
```

Bash専用のrc・関数群はZshへ読み込みません。Sheldonのプラグインや履歴、補完キャッシュは
実環境の通常ディレクトリに作られ、Gitへ取り込みません。
旧ログインシェルの記録は`~/.local/state/dotfiles/shell-before-zsh-*.txt`へ保存します。

2026-10-18時点のエージェントによる実行はsudo制約で止まり、Zshのインストールと実起動は未完了です。
新しい4ファイル（`.zshenv`、`.zshrc`、共通Zsh設定、Sheldon設定）の導入は上記スクリプトに委ねています。
この手順が成功するまで、実環境のログインシェルはBashのままです。

## デュアルモニター配置

外部の`HDMI-A-1`を上、内蔵の`eDP-1`を下に置き、論理座標上で中央を揃えます。

| 出力 | 解像度 | 倍率 | 論理サイズ | 位置 |
|---|---|---|---|---|
| eDP-1（下） | 1920×1080 | 1.5 | 1280×720 | `0x0` |
| HDMI-A-1（上） | 1920×1080 | 1 | 1920×1080 | `-320x-1080` |

内蔵画面を原点に固定します。その他の出力には自動配置のフォールバックを残しています。
設定は`.config/hypr/monitors.lua`です。配置変更前のバックアップは
`~/.local/state/dotfiles/backups/monitors-20261018-202501/monitors.lua`です。
Lua構文は検証済みですが、エージェントからのHyprland接続に失敗したため実配置の確認は未完了です。

## Git

共通のグローバルGit設定も導入対象です（設定一覧は`files.json`が正）。
個人情報・認証・署名鍵はホーム側の非管理ファイルへ分離しています。詳細はルートREADMEを参照してください。

## ブラウザー動画再生中のスクリーンセーバー抑止

ユーザープラグイン`dotfiles.idle`を追加しました。標準のアイドル処理を複製し、ブラウザーの
MPRIS再生状態を見て、再生中だけスクリーンセーバーと自動ロックを抑止します。
停止・一時停止後は通常の150秒／300秒の待機時間へ戻り、停止直後にロックしません。
動画と音声を識別できないため、ブラウザー内の音声再生も対象です。
メディアのタイトルやURLは読み取らず、保存・ログ出力しません。

エージェントからデスクトップIPCへ接続できないため、標準のアイドル処理はまだ切り替えていません。
通常の端末で次を実行して有効化してください。

```sh
~/dotfiles/scripts/enable-browser-idle
```

Omarchyのレジストリでプラグインを有効化し、状態を確認できなければ標準へ戻すスクリプトです。
有効化前のshell.jsonはローカルにバックアップします。再生中と一時停止中に
`omarchy-shell idle status`の`browserMediaPlaying`が切り替わることを確認してください。
元に戻す場合は`omarchy plugin enable omarchy.idle`です。
詳細は`../submodules/omarchy-browser-idle/README.md`を参照してください。

## 通知を自動で閉じる

`dotfiles.notifications`は標準の通知サービスを複製し、重要通知にも15秒の期限を設けます。
通知の下部には残り時間のバーが表示され、ホバー中は表示も一時停止します。
右クリックで閉じる機能と、ホバー中のカウント停止は標準のままです。
通常のデスクトップ端末で`~/dotfiles/scripts/enable-notification-timeout`を実行して有効化します。
元に戻すには`omarchy plugin enable omarchy.notifications`を実行してください。
詳細は`../submodules/omarchy-notification-countdown/README.md`を参照してください。

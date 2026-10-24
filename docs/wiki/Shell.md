# ZshとSheldon

## 読み込み順

Omarchyでは `.zshenv` が標準の `env-bootstrap` を読み、PATHとmise shimsを設定します。
`.zshrc` はOmarchyの環境変数・エイリアスを読み込んでから共通設定へ進みます。
Bash専用のrcや関数はZshへ読み込みません。

| ファイル（common/.config/以下） | 内容 |
|---|---|
| `dotfiles/env.sh` | Bash/Zsh共通の環境変数。POSIX構文で書く |
| `dotfiles/bash.sh` | 共通環境設定の読み込みとBashの履歴 |
| `dotfiles/zsh.zsh` | Zshの履歴・補完・キー操作・ツール初期化 |
| `sheldon/plugins.toml` | プラグインの取得元・読み込み順 |
| `sheldon/completion-init.zsh` | compinitとfzfの連携 |
| `sheldon/omz-aliases.zsh` | Oh My Zshの補助関数・選択したプラグイン |

miseのツール一覧はOSごとに管理します。

## プラグインを更新する

```sh
~/dotfiles/scripts/update-zsh-plugins
```

取得したソースの構文、必要なエイリアス・補助関数、署名付きコミットと検証を確認してから有効化します。
[Gitの個人設定と署名鍵](Git.md)が必要です。成功後は新しい端末を開きます。

Zshは最後に検証した `~/.cache/dotfiles/sheldon.zsh` を使います。
TOMLを書き換えただけでは反映されません。分離した `.zsh` ファイルの内容は次の起動時に読み込みます。
取得・検証に失敗したら旧キャッシュを維持します。
キャッシュがない環境では通常のSheldon読み込みに切り替わります。

取得したソースは `~/.local/share/dotfiles/sheldon/` の世代別ディレクトリに置きます。
変更前のキャッシュは `~/.local/state/dotfiles/backups/` へ退避します。
復元用に古い世代を残すため、自動では削除しません。

## 入力操作

| キー | 操作 |
|---|---|
| Tab | fzfで補完。Enterで選択、`<` / `>` でグループ切り替え |
| Ctrl-R | 履歴検索 |
| Ctrl-T | ファイルを選んで入力欄へ挿入 |
| Alt-C | ディレクトリを選んで移動 |
| Ctrl-Space | globaliasで展開せずスペースを挿入 |

Git・Docker・ComposeのエイリアスはOh My Zshの定義を使います。
`globalias` はSpaceで入力を展開します。globやコマンド置換も展開の対象です。

| 操作 | エイリアス |
|---|---|
| 状態・差分・追加 | `gst`、`gd`、`ga` |
| メッセージを指定してコミット | `gcmsg "message"` |
| メインブランチへ移動 | `gcm` |
| ブランチ・チェックアウト | `gb`、`gco` |
| Docker一覧・ログ・対話exec | `dps`、`dlo`、`dxcit` |
| Compose起動・ログ追従・exec | `dcupd`、`dclf`、`dce` |

`gcm` は以前の `git commit -m` とは異なります。
旧 `gcad` と `git co/br/ci/st` は廃止しました。
通常のコミットは自動署名しますが、`gwip` のように明示的に署名を無効にするエイリアスも上流の定義を保ちます。

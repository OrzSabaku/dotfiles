# dotfiles

設定は「共通」「Omarchy」「Fedora」に分け、各ディレクトリ内をホームディレクトリと同じ配置にします。

```text
common/             OSをまたいで使う設定
  .config/
    dotfiles/       env.sh・bash.sh・zsh.zsh
    ghostty/        共通の見た目・操作設定
    sheldon/        Zshプラグイン一覧
    starship.toml
    nvim/           共通のメインエディタ（LazyVim）
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
experiments/        通常導入しない実験用設定
scripts/            導入・復元・実験起動処理
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

Omarchyの対象はZsh設定を含め63ファイルです。内容・権限が異なる既存ファイルや、無関係なリンクがあれば停止します。
既存設定をバックアップした後、ファイル単位でリンクします。ディレクトリ全体はリンクしません。
詳しくは[Omarchyの設定地図](omarchy/README.md)を参照してください。

Fedoraは従来の方式です。[Fedoraの説明](fedora/README.md)も確認してください。

```sh
python3 ~/dotfiles/install.py --profile fedora --apply
```

Vim設定は保存されていますが導入対象外です。パッケージの導入・更新は行いません。
認証情報・履歴・キャッシュ・個人用Git identity・生成テーマは対象外です。

## Ghosttyシェーダー

シェーダーはプロジェクトルートの`submodules/`配下にまとめて管理します。
`submodules/ghostty-shaders/`は[個人フォーク](https://github.com/Desert-sabaku/ghostty-shaders)、
`submodules/cursor-shaders/`は[上流](https://github.com/sahaj-b/cursor-shaders)を参照します。
雨の方向と連続入力時のアニメーションを改善したコミットを固定しています。

クローン後は次を実行してください。

```sh
git submodule update --init --recursive
```

Ghosttyの`common/.config/ghostty/dotfiles.conf`は`~/dotfiles/submodules/ghostty-shaders/`と
`~/dotfiles/submodules/cursor-shaders/`内のファイルを参照します。
修正はsubmodule内でコミット・pushし、親リポジトリでも参照コミットを更新してください。

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

## Neovim

日常の`nvim`は両OSとも`common/.config/nvim/`のLazyVimを使用します。
Omarchyのテーマ一覧・再読み込みだけ`omarchy/.config/nvim/lua/omarchy/plugins/`に分離しています。
Omarchyが生成する`plugins/theme.lua`へのリンクは従来のままです。
Fedoraの新規導入ではOmarchy連携がなくても共通設定だけで動作します。

自作設定は[実験用設定](experiments/README.md)へ移動しました。
`~/dotfiles/scripts/nvim-experiment`で明示的に起動します。
設定・データ・状態・キャッシュを分離しますが、ホストへのファイルアクセスを制限するものではありません。
旧`nvim-personal`は通常の導入対象から外しています。

## シェルと端末の共通化

- `common/.config/dotfiles/env.sh`: Bash/Zsh共通のEDITOR、bat、fzf表示設定（POSIX構文）。
- `common/.config/dotfiles/bash.sh`: 共通環境設定の読み込みとBashの履歴設定。
- `common/.config/dotfiles/zsh.zsh`: Zshの履歴・補完・キー操作と、存在するツールの初期化。
- `common/.config/sheldon/plugins.toml`: Zshプラグインの取得元・読み込み順と短いテンプレート。
- `common/.config/sheldon/completion-init.zsh`: 補完初期化とfzfの連携設定。
- `common/.config/sheldon/omz-aliases.zsh`: Oh My Zshの依存関数と選択したプラグインの読み込み。
- `common/.config/ghostty/dotfiles.conf`: 透過・余白・カーソル・分割キー。

OmarchyはZshを主シェルにする構成で、Bashも復旧用に残します。Fedoraの`.bashrc`・`.zshrc`は
OS固有の初期化を行ってから共通設定を読み込みます。miseのツール一覧はOSごとに維持しています。
Ghosttyのテーマ・フォントなどはOS側に残しています。
Fedoraのメイン設定名は標準の`config`へ統一し、存在しないシェーダー参照はコメントにしました。
Zshの起動確認にはZsh本体と必要なツールが別途必要です。

## OmarchyへのZsh導入

通常のユーザー端末で次を実行してください（sudoは付けません）。

```sh
~/dotfiles/scripts/setup-zsh
```

Zsh・Sheldonのパッケージ導入、設定の検証・リンク、プラグイン取得、対話シェルの起動テストを
順に実行し、成功した後だけ`chsh`でログインシェルを変更します。パスワード入力が必要な場合があります。
新しい端末、必要なら再ログイン後に反映されます。Bashへ戻すには`chsh -s /usr/bin/bash`を使います。
Bash側の設定、デスクトップ、Ghosttyの起動コマンドは変更しません。

2026-10-18のエージェント実行ではsudoの実行制約によりパッケージ導入で停止しました。
この時点では63ファイル中Zsh用4ファイルは未適用で、ログインシェルはBashのままです。
設定・導入手順の準備と9テストは完了していますが、Zsh本体での検証はスクリプト実行時に行います。

## グローバルGit設定と署名

`~/.config/git/config`は`common/.config/git/config`へリンクし、両OSで共通の差分表示・
ブランチ設定などと、SSH方式のコミット自動署名を管理します。
名前・メール・署名鍵・認証ヘルパーは、リポジトリ外の`~/.config/git/config.private`から読み込みます。
署名の検証先`~/.config/git/allowed_signers`も非管理です。両ファイルは権限600にします。

新しい環境では`common/.config/git/config.private.example`を実環境の`config.private`へコピーし、
公開用の作者名、GitHubのnoreplyメール、既存SSH鍵の場所を設定してください。
この例示ファイルは自動導入しません。秘密鍵は別途安全に用意し、dotfilesへコピーしません。
鍵・作者情報が未設定なら署名に失敗する状態を保ち、無署名へ自動で切り替えません。

個人情報の変更は、共有原本への書き込みを避けて次のように行います。

```sh
git config --file ~/.config/git/config.private user.name YOUR_PUBLIC_ALIAS
git config --file ~/.config/git/config.private user.email YOUR_GITHUB_NOREPLY_EMAIL
git config --file ~/.config/git/config.private user.signingkey ~/.ssh/id_ed25519
```

`git config --global`は共有ファイルを直接書き換えるため、名前・メール・認証情報の保存には使わないでください。
GitHub CLIの認証ヘルパーを設定し直す場合も、非管理ファイルへ書き込みます。

```sh
GIT_CONFIG_GLOBAL="$HOME/.config/git/config.private" gh auth setup-git
```

署名検証には`allowed_signers`へ`メールアドレス 鍵種別 公開鍵本体`の形式で登録し、
`config.private`の`gpg.ssh.allowedSignersFile`でそのファイルを指定します。
この環境では既存のSSH鍵を使い、通常の`git commit`の自動署名と`git verify-commit`を検証済みです。

GitHubでVerifiedと表示するには、公開鍵をGitHubへ署名用の鍵として登録します。
認証用のSSH鍵登録とは別の用途です。今回エージェントからはGitHub認証/APIを確認できていません。

```sh
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "Git commit signing"
```

登録済みの署名鍵がある場合は重複追加せず、その鍵を使用します。
GitHubの案内: https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key

移行前の設定は`~/.local/state/dotfiles/backups/git-global-20261020-021309/`に保存しています。
名前・メールの変更は今後のコミットへ適用します。既存履歴の作者情報は書き換えていません。
リポジトリを公開する前には、設定ファイルだけでなく過去の履歴の作者情報も確認してください。

## ブラウザー再生中のアイドル抑止

Omarchy用の`dotfiles.idle`プラグインを追加しています。標準のスクリーンセーバー・自動ロックの
時間は維持し、ブラウザーの動画・音声再生中だけ抑止します。
有効化は通常のデスクトップ端末で`scripts/enable-browser-idle`を実行してください。
実セッションの再生確認は未完了です。詳しくは[Omarchyの設定地図](omarchy/README.md)を参照してください。

## ZshのGit・Dockerエイリアス

Oh My ZshのGit・Docker・Docker Composeと、入力展開用のglobaliasをSheldonで読み込みます。
Oh My Zsh本体やテーマへは移行しません。必要なGit補助関数・クリップボード関数も読み込みます。
Omarchyの既存Git短縮形を優先する処理は廃止し、標準のプラグイン定義へ揃えます。

| 操作 | エイリアス |
|---|---|
| 状態・差分・追加 | `gst`、`gd`、`ga` |
| コミットメッセージ指定 | `gcmsg "message"` |
| メインブランチへ移動 | `gcm`（以前の`git commit -m`とは異なる） |
| ブランチ・チェックアウト | `gb`、`gco` |
| Docker一覧・ログ・対話exec | `dps`、`dlo`、`dxcit` |
| Compose起動・ログ追従・exec | `dcupd`、`dclf`、`dce` |

旧`gcad`と、Git自身に定義していた`git co/br/ci/st`は廃止します。
プラグインのエイリアスは上流の定義をそのまま使用します。通常のコミットは共有Git設定で自動署名されますが、
`gwip`のように明示的に署名を無効にするエイリアスも、上流の挙動を維持します。
Gitの署名設定自体を変更・無効化するラッパーは追加していません。

`globalias`により、エイリアスの後でSpaceを押すと入力欄で展開されます。
例：`gst` → Space → `git status `。展開せずスペースを入れるにはCtrl-Spaceを使います。
上流の仕様として、エイリアスに加えglobやコマンド置換も入力中に展開します。

プラグインの取得と検証・有効化は、通常の端末で次を実行します。

```sh
~/dotfiles/scripts/update-zsh-plugins
```

取得したプラグインの構文、必要なエイリアスと補助関数、
`gcmsg`による一時リポジトリへの署名付きコミットと検証を確認してから有効化します。
有効化後は新しい端末を開いてください。署名鍵とGitの個人設定が必要です。

Zsh起動時は`~/.cache/dotfiles/sheldon.zsh`の最後に検証したソースを読み込みます。
取得元・読み込み順・TOMLを変更した場合も上のコマンドで更新してください。
分離した`.zsh`ファイルは起動時に読み込むため、内容の編集は新しい端末から反映されます。取得・検証に失敗した場合は旧キャッシュを維持します。
変更前のキャッシュは`~/.local/state/dotfiles/backups/`へ保存します。
取得は世代別の`~/.local/share/dotfiles/sheldon/`で行い、既存キャッシュが参照するプラグインを保護します。
復元に備え古い世代は自動削除しません。
キャッシュがない新規環境では通常のSheldon読み込みへフォールバックします。

2026-10-21のエージェント環境からはGitHubの名前解決に失敗したため、新規プラグインの取得は未完了です。
既存プラグインの起動を維持し、上記コマンドで取得成功後に新しい構成へ切り替わる状態にしています。
実際の上流プラグインを使う最終検証も、その時点で実行されます。
新構成は`zsh-completions` → `compinit` → fzfキー設定 → エイリアス → `fzf-tab` →
`zsh-autosuggestions` → `fast-syntax-highlighting`の順です。旧`zsh-syntax-highlighting`とは併用しません。

- `Tab`: fzfで補完候補を絞り込み、Enterで選択。`<` / `>`で候補グループを切り替えます。
- `Ctrl-R`: fzfでコマンド履歴を検索します。
- `Ctrl-T`: fzfでファイルを選び、コマンドラインへ挿入します。
- `Alt-C`: fzfでディレクトリを選んで移動します。
- `fast-syntax-highlighting`: 入力中のコマンドや対応するサブコマンドを色分けします。

npm・systemdのエイリアスプラグインは追加していません。

## Omarchyプラグインのソース

実環境にはMarketplace掲載の公開リポジトリから、OmarchyのGit管理プラグインとして導入します。
開発・テスト用のソースは引き続きサブモジュールで管理します。

- [`submodules/omarchy-browser-idle`](submodules/omarchy-browser-idle/README.md): ブラウザー再生中のアイドル抑止
- [`submodules/omarchy-notification-countdown`](submodules/omarchy-notification-countdown/README.md): 通知の自動消去と残量バー

導入・更新のコマンドは[Omarchyの設定地図](omarchy/README.md#プラグインの導入と更新)を参照してください。
`~/.config/omarchy/plugins/`の実行用コードはdotfilesからリンクせず、`omarchy plugin update`で更新します。
各サブモジュールの編集や参照コミットの変更は、実行用コードには反映されません。
個人の有効化状態は`omarchy/.config/omarchy/shell.json`が管理します。
親のGitコミットは各サブモジュールのバージョンを固定します。

新しい2リポジトリの作成とpushは、通常の端末で以下を実行します。

```sh
~/dotfiles/scripts/publish-omarchy-plugins
```

旧`Desert-sabaku/omarchy-plugins`も削除する場合は`--delete-legacy`を付けます。
両方のpushとGitHub上のコミット一致を確認できた場合だけ削除へ進みます。
旧リポジトリに想定外の更新があった場合は削除しません。通常の公開処理では旧リポジトリを残します。
旧履歴は切り出し前に`~/.local/state/dotfiles/backups/plugin-split-*/omarchy-plugins.bundle`へ保存しています。
Marketplaceへの申請は公開・実機確認後の別工程です。

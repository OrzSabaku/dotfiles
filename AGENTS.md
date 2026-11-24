# このリポジトリで作業するエージェントへ

## 目的とユーザーの方針

Fedora由来のdotfilesを、Omarchyでも安全に使い、普段の操作を揃えるリポジトリです。
OSに依存しない設定は積極的に共通化し、OS固有の初期化・デスクトップ連携だけを分離してください。
単なる移行の経緯を理由に設定を分けたり、同じ値を複製したりしないでください。
ユーザーは復旧の手間と既存環境との競合を懸念しています。動作を保ち、戻せる変更を優先します。
説明や作業報告は日本語を基本とします。
読みやすさを常に優先し、目的が分かる名前・短いメソッド・追いやすい実行順を意識してください。

## 構成

作業ディレクトリは既定の`~/.local/share/chezmoi`です。`chezmoi cd`で移動できます。

- `home/`: chezmoiのsource state。`.chezmoiroot`でこのディレクトリを指定します。
- `home/dot_config/`: OSに依存しない設定と、条件付きで配置するOS固有設定。
- `home/.chezmoitemplates/<環境>/`: `.zshrc`など、同じ配置先で内容が異なるOS別設定。
- `home/.chezmoiignore`: 環境・アプリによる対象選択。共通設定をOS別に複製しないでください。
- `home/.chezmoi.toml.tmpl`: 初期化時に環境と対象アプリを選び、ローカル設定を生成します。
- `experiments/`: 通常の導入対象に含めない実験用設定。
- `scripts/`: Ruby標準ライブラリで書くセットアップ・プラグイン更新。Zshの状態検証はZshに残します。
- `tests/`: Minitestによる仮ホームへの配置と、スクリプト・シェル・Git設定の検証。
- `examples/`: 設定の記入例。詳しい手順や補足メモはGitHub Wikiで管理します。

`dot_`は先頭の`.`、`private_`は非公開権限、`executable_`は実行権限、`empty_`は空ファイルの配置を表します。
`exact_`や`.chezmoiremove`で管理外ファイルを消す構成は使わないでください。

## 現在の運用

- 実環境には通常ファイルを配置します。原本の編集だけでは反映されず、`chezmoi diff` → `chezmoi apply`で反映します。
- アプリが書き戻した設定は差分を確認し、通常ファイルは`chezmoi re-add <パス>`で取り込みます。
  OS別テンプレートの設定は対応する`.chezmoitemplates/<環境>/`へ反映します。
- 環境・対象アプリの選択は非管理の`~/.config/chezmoi/chezmoi.toml`に保存します。
  対象から外す操作は既存ファイルを削除しません。OSを切り替える場合も残存ファイルを確認してください。
- OmarchyはZshを主シェルにする構成。`scripts/setup-zsh.rb`で導入・検証してからログインシェルを変更します。
  Bashの設定は復旧用に残します。実際の導入状態は`command -v zsh`と`getent passwd`で確認してください。
- 共通の`env.sh`はBash/Zsh両方から読めるPOSIX構文。Bash固有処理は`bash.sh`、Zsh固有処理は`zsh.zsh`へ。
- ZshとSheldonは共通管理で、両OSの入口から使用します。Omarchyでは`.zshenv`が標準のPATH設定、
  `.zshrc`が標準環境・エイリアスと共通Zsh設定を読み込みます。Bash固有のrc・関数群はZshへ読み込みません。
- Ghosttyの透過・余白・カーソル・分割キーは共通。テーマ・フォント・OS連携は環境側に残します。
- miseのツール一覧・設定は`.chezmoitemplates/common/config/mise/config.toml`に集約し、OS別の断片は持ちません。
  Omarchy標準のCLIは`[tools]`から`[bootstrap.packages]`の`pacman:`宣言へ振り分けます。
  標準一覧を読み取り、仮想パッケージ名は`expac`のローカルProvides情報で解決します。手書きの除外一覧は持ちません。
  `[runtimes]`は常にmise管理です。chezmoi apply・mise installからOSパッケージを導入しません。
  状態確認は`mise bootstrap packages status`、導入はdry-run後に`mise bootstrap packages apply`で明示的に行います。
  パッケージ更新はOmarchyに任せます。
- `gh`・`chezmoi`は検証済みのバージョンに固定し、`.github/renovate.json`で更新PRの対象にします。
  自動マージはしません。試行対象外のツール・`[runtimes]`・OSパッケージへ対象を広げないでください。
- 設定ファイルの配置・部分更新・OS差分はchezmoiで管理します。miseにはツール・環境変数・タスク・パッケージ導入の宣言を任せます。
- OpenCodeの`cli.json`・`opencode.json`はchezmoiの`modify_`テンプレートと共通のRuby処理で部分更新します。
  コメント・管理外の設定を保持し、反映はほかの設定と同じく`chezmoi diff`→`chezmoi apply`で行います。
- 通常の`nvim`は共通のLazyVim。Omarchyのテーマ一覧・再読み込みだけOS側の追加設定です。
- 自作Neovim設定は`experiments/nvim-experiment/`。`mise run --skip-tools nvim-experiment`で明示的に起動します。
  タスクは`home/dot_config/mise/conf.d/nvim-experiment.toml.tmpl`で共通管理し、呼び出し元のディレクトリを維持します。
  `NVIM_APPNAME`で設定・データ・状態・キャッシュを分けますが、ファイルアクセスの隔離ではありません。
  Docker環境はまだ作っていません。旧`nvim-personal`のリンク・関数は廃止済みです。
- 旧Vim設定と歓迎画面用Zprofileは`experiments/`に記録として残していますが、導入しません。

## 安全に変更する

1. 作業前に`git status`、実ファイル、リンク先、読み込み順を確認し、ユーザーの未コミット変更を保護してください。
2. 内容を変える作業と配置を変える作業を区別し、配置変更では移行前後の内容・権限を比較してください。
3. 適用前に`chezmoi diff`と`chezmoi apply --dry-run --verbose`で確認してください。
4. 安全機構はchezmoi標準を使います。通常の適用で`--force`を使わず、競合は差分を確認して解消します。
   独自インストーラーや毎回のバックアップ処理を再実装しないでください。
5. 認証情報、Git identity、履歴、キャッシュ、ブラウザー状態、生成テーマは管理対象外です。
   Gitの共有設定は`home/dot_config/git/config`、個人情報は実環境の`~/.config/git/config.private`です。
   個人情報・鍵・認証ヘルパーには`git config --global`を使わず、非管理ファイルを`--file`で指定します。
   コミットはSSH署名が既定です。署名に失敗した際に無断で`--no-gpg-sign`へ逃げないでください。
6. Omarchyの本体`/usr/share/omarchy/`は編集しません。標準設定への参照を維持します。
   対応するOmarchyスキルが利用できる場合は、デスクトップ・端末・Omarchy設定の作業で使用してください。
7. 過去を見るだけなら`git show`を使います。Gitで原本を戻しても実環境は変わらず、反映にはchezmoiの適用が必要です。
8. 必要な変更は認められた範囲で進め、通常の可逆的な作業のたびに確認を求める必要はありません。
   依頼範囲を超えるツール導入や、設定全体のリセットを勝手に行わないでください。

## コマンドと検証

テストを追加・変更する前に、保証する動作と保証しない範囲を示してください。
テストは、壊れたときに困る動作や安全性を基準に選びます。
管理ファイル数、設定値・ツール一覧の写し、原本との単純な一致は固定しません。
変換処理は小さな入力例と期待する結果で検証し、現在の設定一覧から期待値を組み立てて処理を再実装しないでください。
管理外データ・認証情報の保持、OS・アプリ選択の境界、失敗時に既存環境を壊さないことを優先します。
空白・改行は、保持自体が仕様の部分更新を除き固定しません。外部ツール自体の標準動作を確かめるだけのテストは不要です。
テストの準備・実行も標準ライブラリとMinitestを優先します。独自のコマンド結果型や汎用実行基盤を作らず、
失敗の検証にはOpen3の戻り値をそのまま使ってください。共通ヘルパーは隔離・診断など必要な処理に絞ります。

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
chezmoi verify
bundle exec rake test
git diff --check
```

- chezmoi構成変更では上記テストを実行します。テストは仮ホームを使い、実環境に導入しません。
- テンプレートはOmarchy・Fedoraの両方を検証し、権限と管理外ファイルの保持も確認します。
- Rubyスクリプトは`ruby -c <ファイル>`、`bundle exec rake test`、`bundle exec rubocop --cache false`で検証します。パッケージ導入や`chsh`の実行はモックに置き換えます。
- シェル変更は構文検証と新しいシェルでの起動確認。Zsh未導入なら未検証と明示します。
- Ghosttyは`ghostty +validate-config`で確認します。
- Hyprland Lua変更後は`hyprctl reload`、`hyprctl configerrors`で確認します。
  エージェント環境ではソケット接続が失敗した実績があります。成功したと扱わず制約を報告してください。
- Neovim変更は共通設定単独とOmarchy追加設定ありの両方を確認します。
  起動確認だけのために、プラグイン取得や外部ツール導入を発生させないでください。
- chezmoiのapplyからパッケージ導入、mise更新、ログインシェル変更を自動実行しないでください。

## Rubyの開発

Gemfile・Gemfile.lockで開発用gemを管理し、テストはMinitestで書きます。
スクリプトの実行には追加gemを要求しないでください。
既存ツールとRuby標準ライブラリを優先し、自作の処理は必要最小限にしてください。
Linux x86_64用バイナリは`.github/workflows/native-scripts.yml`でビルドします。
ローカル用のビルドタスクや実行モード切り替えは追加しないでください。
ネイティブ版の検証はCIのビルド後に`bundle exec ruby -Itests tests/native_test.rb`を明示的に実行します。
開発手順は[WikiのRubyスクリプトの開発](https://github.com/OrzSabaku/dotfiles/wiki/Ruby-Development)を参照してください。

## Gitの運用

ユーザーは設定保存のためのローカルコミットを許可しています。意味のある単位でコミットして構いません。
**毎コミットのタグ付けは不要です。** 初期状態、重要な移行の前後、安定版など、
戻り先として名前を付けたい重要スナップショットだけにタグを使ってください。
既存タグは保持します。リモートへの送信は明示的な依頼がある場合だけ行います。

Zshプラグインは`home/dot_config/sheldon/plugins.toml`で管理します。
Git・Docker・ComposeのエイリアスはOh My Zshの選択したファイルを使用し、自前の旧Git短縮形は維持しません。
プラグインのエイリアスは上流の挙動を維持し、`gwip`などを独自に除去・改変しないでください。
通常のコミットの自動署名は維持します。エージェント自身のコミットで署名を迂回してはいけません。
変更後は`scripts/update-zsh-plugins.rb`で取得・検証してから生成済みキャッシュを切り替えます。
Zsh起動時は最後に検証したキャッシュを使用するため、TOMLの編集だけでは既存環境へ即反映されません。

## 文書の運用

READMEは個人用の短いメモです。構成・よく使うコマンド・忘れると困る注意に絞ってください。
詳しい手順や補足メモはGitHub Wikiを正本とし、今後もWikiへまとめます。`docs/`などに同じ文書を複製しないでください。
値や処理を選んだ理由は設定コメント、通常の変更経緯はGit履歴に残します。
設定変更で操作が変わったら該当するメモも直し、重複説明や完了した作業の報告を増やさないでください。
Wikiへの送信・編集も、ほかのリモート送信と同様に明示的な依頼がある場合だけ行います。

## Zshの初回導入

通常のユーザー端末で`~/.local/share/chezmoi/scripts/setup-zsh.rb`を実行します。
パッケージ導入、chezmoi初期化、生成内容の構文検証、適用、プラグイン取得、起動テストの後に`chsh`します。
途中で失敗した場合にログインシェルを変更しない順序を維持してください。
エージェント環境ではsudoが制限される場合があります。導入済みかは現在の実環境で確認してください。

## Omarchyプラグイン

`dotfiles.idle`と`dotfiles.notifications`はそれぞれ独立した公開リポジトリで開発します。
プラグインの開発用サブモジュール・公開用スクリプト・プラグイン本体のテストはdotfilesに置きません。
実環境は`~/.config/omarchy/plugins/<ID>/`内の独立したGitリポジトリから読み込み、
`omarchy plugin add`・`omarchy plugin update`で管理します。実行用コードをdotfilesからリンクしないでください。
dotfilesは有効化状態と標準コマンドによる導入手順を管理します。独自の有効化ヘルパーは必須にしません。
2件ともMarketplace掲載済みです。コード変更は各リポジトリを別途チェックアウトして行い、
実環境への反映には公開後に`omarchy plugin update`と必要なシェル再起動を使います。
リモートへの送信・Issueへの投稿はユーザーからの明示的な依頼がある場合だけ行ってください。

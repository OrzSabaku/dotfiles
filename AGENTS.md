# このリポジトリで作業するエージェントへ

## 目的とユーザーの方針

Fedora由来のdotfilesを，Omarchyでも安全に使い，普段の操作を揃えるリポジトリです．
OSに依存しない設定は積極的に共通化し，OS固有の初期化・デスクトップ連携だけを分離してください．
単なる移行の経緯を理由に設定を分けたり，同じ値を複製したりしないでください．
ユーザーは復旧の手間と既存環境との競合を懸念しています．動作を保ち，戻せる変更を優先します．
説明や作業報告は日本語を基本とします．
読みやすさを常に優先し，目的が分かる名前・短いメソッド・追いやすい実行順を意識してください．

## 構成

作業ディレクトリは既定の `~/.local/share/chezmoi` です．`chezmoi cd` で移動できます．

- `home/`: chezmoiのsource state．`.chezmoiroot` でこのディレクトリを指定します．
- `home/dot_config/`: OSに依存しない設定と，条件付きで配置するOS固有設定．
- `home/.chezmoitemplates/<環境>/`: `.zshrc` など，同じ配置先で内容が異なるOS別設定．
- `home/.chezmoiignore`: 環境・アプリによる対象選択．共通設定をOS別に複製しないでください．
- `home/.chezmoi.toml.tmpl`: 初期化時に環境と対象アプリを選び，ローカル設定を生成します．
- `experiments/`: 通常の導入対象に含めない実験用設定．
- `scripts/`: Ruby標準ライブラリで書くセットアップ・プラグイン更新．Zshの状態検証はZshに残します．
- `tests/`: Minitestによる仮ホームへの配置と，スクリプト・シェル・Git設定の検証．
- `examples/`: 設定の記入例．詳しい手順や補足メモはGitHub Wikiで管理します．

`dot_` は先頭の `.`，`private_` は非公開権限，`executable_` は実行権限，`empty_` は空ファイルの配置を表します．
`exact_` や `.chezmoiremove` で管理外ファイルを消す構成は使わないでください．

## 境界と設計ルール

- **役割分担**: 設定ファイルの配置・部分更新・OS差分はchezmoi，ツール・環境変数・タスク・パッケージ導入の宣言はmiseで管理します．
- **配置と残存ファイル**: 実環境には通常ファイルを配置します．対象外化やOS切替で既存ファイルは削除されないため，切替時は残存ファイルを確認してください．OS別テンプレートは `home/.chezmoitemplates/<環境>/` を直接編集します．
- **シェル（Bash / Zsh）**:
  - `env.sh` はBash/Zsh両方から読めるPOSIX構文に保ち，Bash固有処理は `bash.sh`，Zsh固有処理は `zsh.zsh` に分離します．Bash固有のrc・関数群をZshへ読み込まないでください．
  - OmarchyはZshを主シェルとし，Bash設定は復旧用に残します．実環境の状態は `command -v zsh` と `getent passwd` で確認してください．
- **Zshプラグイン・補完（Sheldon）**:
  - プラグイン，補完の検索先・初期化順，fzf・zoxide・Atuinの連携は `home/dot_config/sheldon/plugins.toml` に集約します．
  - CLI補完は `home/dot_config/sheldon/generate-completions.zsh` にまとめ，`scripts/update-zsh-plugins.rb` で未公開世代に生成・検証してから切り替えます（`_名前` はfpath，`名前.zsh` はcompinit後にsource）．未導入CLIは省略し，導入済みCLIの生成失敗時は以前のキャッシュと補完を保持します．
  - Zsh起動時は検証済みキャッシュを使うため，TOML編集だけでは既存環境へ反映されません．
  - Git・Docker・ComposeのエイリアスはOh My Zshの選択ファイルを使用し，自前の旧Git短縮形は維持せず，上流エイリアス（`gwip` 等）も独自に除去・改変しないでください．
- **Ghostty**: 透過・余白・カーソル・分割キーは共通化し，テーマ・フォント・OS連携だけをOS側に残します．
- **miseとパッケージ管理**:
  - ツール一覧・設定は `.chezmoitemplates/common/config/mise/config.toml` に集約し，OS別の断片や手書きの除外一覧を持ちません．
  - `[runtimes]` は常にmise管理です．Omarchy標準CLIは `expac` のローカルProvides情報から `[bootstrap.packages]` へ振り分けます．`chezmoi apply` や `mise install` からOSパッケージを自動導入せず，更新もOmarchyに任せます．
- **Renovate**: `gh`・`chezmoi` のみ検証済みバージョンに固定し，`.github/renovate.json` で更新PRの対象にします（`automerge: false` を維持）．対象外のツール・`[runtimes]`・OSパッケージへ広げないでください．
- **OpenCode 1.x**: `~/.config/dotfiles/opencode/` に管理設定を分離し，miseの環境変数経由で標準マージします．既存のユーザー設定や認証情報は編集しないでください．
- **Neovim・実験用設定**: 通常の `nvim` は共通LazyVimとし，Omarchy側にはテーマ一覧・再読み込みだけを追加します．実験用設定は `experiments/` に置き，通常導入へ含めません（旧 `nvim-personal` のリンク・関数は復活させないでください）．

## 安全に変更する

1. 作業前に `git status`，実ファイル，リンク先，読み込み順を確認し，ユーザーの未コミット変更を保護してください．
2. 内容を変える作業と配置を変える作業を区別し，配置変更では移行前後の内容・権限を比較してください．
3. 適用前に `chezmoi diff` と `chezmoi apply --dry-run --verbose` で確認してください．
4. 安全機構はchezmoi標準を使います．通常の適用で `--force` を使わず，競合は差分を確認して解消してください．独自インストーラーや毎回のバックアップ処理を再実装しないでください．
5. 認証情報，Git identity，履歴，キャッシュ，ブラウザー状態，生成テーマは管理対象外です．Gitの共有設定は `home/dot_config/git/config`，個人情報は実環境の `~/.config/git/config.private` に置きます．個人情報・鍵・認証ヘルパーには `git config --global` を使わず，`--file` で非管理ファイルを指定してください．
6. Omarchy本体 `/usr/share/omarchy/` は編集しません．標準設定への参照を維持し，利用可能なOmarchyスキルがある場合はデスクトップ・端末・Omarchy設定の作業で使用してください．
7. 過去を見るだけなら `git show` を使います．Gitで原本を戻しても実環境は変わらず，反映にはchezmoiの適用が必要です．
8. 必要な変更は認められた範囲で進め，通常の可逆的な作業のたびに確認を求める必要はありません．依頼範囲を超えるツール導入や，設定全体のリセットを勝手に行わないでください．

## コマンドと検証

テストを追加・変更する前に，保証する動作と保証しない範囲を示してください．
テストは，壊れたときに困る動作や安全性を基準に選びます．
管理ファイル数，設定値・ツール一覧の写し，原本との単純な一致は固定しません．
変換処理は小さな入力例と期待する結果で検証し，現在の設定一覧から期待値を組み立てて処理を再実装しないでください．
管理外データ・認証情報の保持，OS・アプリ選択の境界，失敗時に既存環境を壊さないことを優先します．
空白・改行は，保持自体が仕様の部分更新を除き固定しません．外部ツール自体の標準動作を確かめるだけのテストは不要です．
テストの準備・実行も標準ライブラリとMinitestを優先し，独自のコマンド結果型や汎用実行基盤を作らず，失敗の検証にはOpen3の戻り値をそのまま使ってください．共通ヘルパーは隔離・診断など必要な処理に絞ります．

```sh
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
chezmoi verify
bundle exec rake test
git diff --check
```

- chezmoi構成変更ではrakeでテストを実行します．テストは仮ホームを使い，実環境に導入しません．
- テンプレートはOmarchy・Fedoraの両方を検証し，権限と管理外ファイルの保持も確認します．
- Rubyスクリプトは `ruby -c <ファイル>`，`bundle exec rake test`，`bundle exec rubocop --cache false` で検証します．パッケージ導入や `chsh` の実行はモックに置き換えます．
- シェル変更は構文検証と新しいシェルでの起動確認を行います．Zsh未導入なら未検証と明示してください．
- Ghosttyは `ghostty +validate-config` で確認します．
- Hyprland Lua変更後は `hyprctl reload`，`hyprctl configerrors` で確認します．エージェント環境ではソケット接続が失敗した実績があるため，成功したと扱わず制約を報告してください．
- Neovim変更は共通設定単独とOmarchy追加設定ありの両方を確認します．起動確認だけのために，プラグイン取得や外部ツール導入を発生させないでください．
- `chezmoi apply` からパッケージ導入，mise更新，ログインシェル変更を自動実行しないでください．

## Rubyの開発

- `Gemfile`・`Gemfile.lock` で開発用gemを管理し，テストはMinitestで書きます．スクリプトの実行には追加gemを要求しないでください．
- 既存ツールとRuby標準ライブラリを優先し，自作の処理は必要最小限にしてください．
- Linux x86_64用バイナリは `.github/workflows/native-scripts.yml` でビルドします．ローカル用のビルドタスクや実行モード切り替えは追加しないでください．
- ネイティブ版の検証はCIのビルド後に `bundle exec ruby -Itests tests/native_test.rb` を明示的に実行します．
- 開発手順は [WikiのRubyスクリプトの開発](https://github.com/OrzSabaku/dotfiles/wiki/Ruby-Development) を参照してください．

## Gitの運用

- ローカルコミットは意味のある単位で行って構いません．
- **毎コミットのタグ付けは不要です．** 初期状態，重要な移行の前後，安定版など，戻り先として名前を付けたい重要スナップショットだけにタグを使ってください．既存タグは保持します．
- 通常のコミットのSSH署名は維持します．署名に失敗しても無断で `--no-gpg-sign` へ逃げないでください．
- リモートへの送信は明示的な依頼がある場合だけ行います．

## 文書の運用

役割分担を保ち，同じ説明を複数箇所に書かないでください．

- **`README.md`**: 入口・構成の概観・高頻度コマンド・Wikiや局所READMEへのリンクに絞ります．初回やOS別の詳細手順，個別の内部仕様を追記しないでください．
- **GitHub Wiki**: 詳細手順・OS別設定・ツール連携の仕組み・補足メモの正本です．`docs/` などに同じ文書を複製しないでください．Wikiへの送信・編集は明示的な依頼がある場合だけ行います．
- **`AGENTS.md`**: エージェントが守るべき境界・禁止事項・検証方針に絞ります．READMEやWikiと使い方説明を重複させないでください．
- **局所README**（`experiments/README.md` など）: そのディレクトリ内で完結する使い方や前提を書きます．
- **設定コメントとGit履歴**: 値や処理を選んだ理由（Why）は設定コメント，通常の変更経緯はGit履歴に残します．設定変更で操作が変わったら該当文書を更新し，完了報告や重複説明を増やさないでください．
- **表記**: 日本語文書の句読点は全角のコンマ（`，`）とピリオド（`．`）を使います．

## Zshの初回導入

通常のユーザー端末で `~/.local/share/chezmoi/scripts/setup-zsh.rb` を実行します．
パッケージ導入，chezmoi初期化，生成内容の構文検証，適用，プラグイン取得，起動テストの後に `chsh` する順序（途中で失敗したらログインシェルを変更しない）を維持してください．
エージェント環境では `sudo` が制限される場合があります．導入済みかは現在の実環境で確認してください．

## Omarchyプラグイン

- `dotfiles.idle` と `dotfiles.notifications` はそれぞれ独立した公開リポジトリで開発します．プラグインの開発用サブモジュール・公開用スクリプト・プラグイン本体のテストはdotfilesに置きません．
- 実環境は `~/.config/omarchy/plugins/<ID>/` 内の独立したGitリポジトリから読み込み，`omarchy plugin add`・`omarchy plugin update` で管理します．実行用コードをdotfilesからリンクしないでください．
- dotfilesでは有効化状態と標準コマンドによる導入手順だけを管理し，独自の有効化ヘルパーは必須にしません．
- 2件ともMarketplace掲載済みです．コード変更は各リポジトリを別途チェックアウトして行い，実環境への反映には公開後に `omarchy plugin update` と必要なシェル再起動を使います．
- リモートへの送信・Issueへの投稿は明示的な依頼がある場合だけ行ってください．

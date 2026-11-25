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
- NeovimのchezmoiテンプレートはGo templateの構文強調・構文診断を使用します。
  整形は `Space c f` で明示的に実行します（TOMLはTaplo、JSONはBiome、シェルはshfmtなど、対象形式のCLIが必要）。
  保存時の自動整形・自動applyは行いません。診断はテンプレート構文が対象で、展開後の設定は `chezmoi diff` でも確認します。
- 実ファイル側の変更は差分を確認してから取り込みます。通常ファイルは `chezmoi re-add <パス>`、
  OS別テンプレートは `home/.chezmoitemplates/<環境>/` の該当ファイルを編集します。
- Codex・Amp・PiとDiscordは `modify_` テンプレートで好みの項目だけ更新します。
  これらは `re-add` せず原本を編集します。認証情報・信頼設定・ウィンドウ状態は実ファイルに残します。
  AI設定の対象選択は `apps.ai`。Herdr・Atuinが生成する連携コードは各ツールで導入します。
- OpenCode 1.xは `~/.config/dotfiles/opencode/` の設定を標準マージします。既存設定は編集しません。
  miseが `OPENCODE_CONFIG`・`OPENCODE_TUI_CONFIG` を設定するため、新しい端末から起動します。
  管理設定はグローバル設定より優先され、プロジェクト設定で上書きできます。
- Gitの名前・メール・署名鍵は非管理の `~/.config/git/config.private` へ。
  [記入例](examples/git/config.private.example)を参照し、権限は `600` にします。
- Gitで原本を戻した場合も、反映前に `chezmoi diff` を確認します。リモート送信は手動です。

## 管理元で使うスクリプト

Rubyが必要です（追加gemは不要）。`chezmoi cd` で移動してから実行します。

- `scripts/setup-zsh.rb` — OmarchyでのZsh初回導入。通常の端末で実行します。
- `scripts/update-zsh-plugins.rb` — Sheldon設定の適用後にプラグイン取得とCLI補完の生成・検証を行い、キャッシュを切り替えます。ツールの導入・更新後も実行し、完了後に新しい端末を開きます。

実験用Neovimは `mise run --skip-tools nvim-experiment`（ファイル指定は `mise run --skip-tools nvim-experiment -- <ファイル>`）で起動します。
chezmoiで配置するグローバルタスクです。[実験用設定](experiments/README.md)を参照。

## 構成

`home/` がchezmoiの管理対象です。共通設定は `home/dot_config/`、OS別の内容は
`home/.chezmoitemplates/` に保存し、`home/.chezmoiignore` で配置対象を選びます。
FedoraではGNOMEの操作・見た目、自動起動、既定アプリも保存します。
GNOMEの保存値は `home/.chezmoitemplates/fedora/gnome.ini`。変更時の `chezmoi apply` で
記載したキーだけをdconfへ反映します。拡張機能やアプリ本体の導入は別途必要です。
VS Codeとhtopの設定はOS共通です。`experiments/` は通常の導入には含めません。
Fedoraの追加RPMリポジトリとパッケージ一覧は `home/.chezmoidata/fedora.yaml` に記録します。
導入テンプレートは明示的に生成・実行します（DNF5とそのconfig-manager・COPRプラグインが必要）。

```sh
chezmoi execute-template < home/.chezmoitemplates/fedora/setup-packages.rb.tmpl > /tmp/setup-packages.rb
ruby /tmp/setup-packages.rb          # コマンドのプレビュー
ruby /tmp/setup-packages.rb --apply  # DNFの確認を経て導入
```

既存のベンダーリポジトリは上書きしません。署名鍵の取得方法が未確定なリポジトリは、
公式手順で鍵を用意してから導入します。`chezmoi apply`からは実行しません。

既定アプリとランチャー、ユーザーフォルダー、音声、GUIアプリの設定も管理します。
自動起動の抑制・Wayland連携・音声入力のサービス定義はOmarchyだけに配置します。
サービスの有効化や起動は自動実行しません。
GTKの文字倍率・Evinceの表示設定は `dconf load / < ~/.config/dotfiles/desktop.dconf` で別途反映します。
個人用Composeマクロ、各アプリの履歴・認証情報、生成テーマ、`/etc` のシステム設定は保存しません。

開発・テストとLinux x86_64用バイナリの配布手順は [Rubyスクリプトの開発](https://github.com/OrzSabaku/dotfiles/wiki/Ruby-Development)を参照してください。

補足は [Omarchy](https://github.com/OrzSabaku/dotfiles/wiki/Omarchy) と [GitHub Wiki](https://github.com/OrzSabaku/dotfiles/wiki)へ。

miseのツール一覧・共通設定は `home/.chezmoitemplates/common/config/mise/config.toml`、
両OSで共用します。反映後、必要なツールを `mise install <ツール名>` で導入します。
Omarchy標準のCLIは `[bootstrap.packages]` にpacman管理として出力します。
確認は `mise bootstrap packages status`、導入前の確認は `mise bootstrap packages apply --dry-run`。
導入は `mise bootstrap packages apply` で明示的に行い、更新はOmarchyに任せます。
共通一覧の `[tools]` はOmarchy標準一覧と同名ならOS版を使い、`[runtimes]` は常にmiseで管理します。
仮想パッケージ名（`nvim`など）は、標準の `expac` でローカルのpacman情報を読み、実名へ解決します。

`gh`・`chezmoi`は動作確認したバージョンに固定し、Renovateの更新PRを確認して更新します（自動マージなし）。
初回は [Renovate App](https://github.com/apps/renovate) でこのリポジトリを許可し、
`.github/renovate.json` を既定ブランチへ反映します。マージ後は `chezmoi diff` → `chezmoi apply`、
`mise install gh chezmoi` で反映します。

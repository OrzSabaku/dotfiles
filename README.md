# dotfiles

FedoraとOmarchyで使う個人設定をchezmoiで管理するリポジトリです．
普段はOmarchy・Zsh・Ghostty・Neovimを使います．

## 導入

Gitとchezmoiが必要です．管理元は既定の `~/.local/share/chezmoi` です．

```sh
chezmoi init OrzSabaku
chezmoi diff
chezmoi apply --dry-run --verbose
chezmoi apply
```

- `init` で環境（`omarchy` / `fedora`）と管理対象アプリを選びます．選択は `~/.config/chezmoi/chezmoi.toml` に保存され，`chezmoi init --prompt` で選び直せます．
- パッケージ導入・ツール更新・ログインシェル変更は自動実行しません．

## 普段の操作

```sh
chezmoi edit ~/.config/starship.toml
chezmoi diff
chezmoi apply
```

- **原本の反映**: 管理元での編集（移動は `chezmoi cd`）や `git` で戻した変更は，`chezmoi diff` を確認してから `chezmoi apply` で反映します．リモート送信は手動です．
- **実ファイル変更の取り込み**: 通常ファイルは `chezmoi re-add <パス>`，OS別テンプレートは `home/.chezmoitemplates/<環境>/` を直接編集します．
- **`modify_` テンプレート**: Codex・Amp・Pi・Discord は好みの項目だけ部分更新するため，`re-add` せず原本を編集します（認証情報・信頼設定・ウィンドウ状態は実ファイルに残ります）．
- **Gitの個人情報**: 名前・メール・署名鍵は非管理の `~/.config/git/config.private` に置きます（[記入例](examples/git/config.private.example)，権限 `600`）．

## スクリプトと実験設定

Rubyが必要です（追加gemは不要）．`chezmoi cd` で移動してから実行します．

| コマンド | 用途 |
| :--- | :--- |
| `scripts/setup-zsh.rb` | OmarchyでのZsh初回導入（通常の端末で実行） |
| `scripts/update-zsh-plugins.rb` | Sheldon適用後・ツール更新後のプラグイン取得とCLI補完キャッシュ更新 |
| `mise run --skip-tools nvim-experiment` | 実験用Neovimの起動（詳細は [experiments/README.md](experiments/README.md)） |

## 構成と詳細ドキュメント

| パス | 役割 |
| :--- | :--- |
| `home/` | chezmoiの管理対象（共通設定は `home/dot_config/`，OS別は `home/.chezmoitemplates/`，配置選択は `home/.chezmoiignore`） |
| `scripts/` | セットアップ・プラグイン更新用Rubyスクリプト |
| `examples/` | 非管理設定の記入例 |
| `experiments/` | 通常の導入対象に含めない実験用設定 |

OS別のパッケージ・デスクトップ設定，miseとbootstrapの仕組み，OpenCode・AI設定の運用，Rubyスクリプトの開発手順はGitHub Wikiにまとめています．

- [GitHub Wiki](https://github.com/OrzSabaku/dotfiles/wiki)
- [Omarchy](https://github.com/OrzSabaku/dotfiles/wiki/Omarchy)
- [Rubyスクリプトの開発](https://github.com/OrzSabaku/dotfiles/wiki/Ruby-Development)

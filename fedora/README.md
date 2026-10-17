# Fedora固有の設定

このディレクトリ内はホームと同じ配置です。Bash/ZshのOS固有の入口、Ghosttyのテーマ・フォント、miseの設定を保存しています。
Bash/Zshの個人設定、Sheldon、Ghosttyの操作設定、Starship、メインNeovim（LazyVim）は
`../common/.config/`を使用します。
Neovimはinit.luaだけでなく設定一式をファイル単位で導入します。
Omarchy固有のテーマ追加設定や、自作設定の実験は導入しません。
`.vimrc`は元環境の記録として残していますが、導入しません。

```sh
python3 ~/dotfiles/install.py --profile fedora --apply
```

既存ファイルの内容が異なる場合や、別のリンクがある場合は停止します。
初回の既存設定取り込みに限り`--import-existing`を追加できます。
この従来の方式にはOmarchy版の自動バックアップ・復元機能はありません。
OS・ユーザー固有のパスや依存ツールは導入前に確認してください。
パッケージを自動でインストールする処理はありません。

Zshのロケール`LANG=ja_JP.UTF-8`はこのOS側の`.zshrc`に残しています。
共通設定のツール初期化はPATHからmiseなどを探し、未導入ならスキップします。
Ghosttyは`.config/ghostty/config`を導入します。以前の`config.ghostty`は導入しません。
シェーダー実体がリポジトリにないため、旧パスの参照はコメントとして残しています。
以前の設定が既にある環境では、差分を確認して手動で解消してから導入してください。
この環境ではFedora本体・Zshの起動確認はしていません。仮ホームへのリンク導入と
Ghosttyの構文検証を行っています。

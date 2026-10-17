# Fedora固有の設定

このディレクトリ内はホームと同じ配置です。Bash・Zsh・Ghostty・mise・Sheldonの設定を保存しています。
StarshipとメインエディタのNeovim（LazyVim）は`../common/.config/`の設定を使用します。
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

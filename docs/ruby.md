# Rubyスクリプトの開発

このリポジトリの開発用gemはGemfileで管理します。スクリプト自体はRuby標準ライブラリだけで動きます。

```sh
bundle install
bundle exec rake test
bundle exec rubocop --cache false
```

テストはMinitestです。仮ホームとダミーコマンドを使い、パッケージ導入・ログインシェル変更・プラグイン取得を実行しません。
chezmoiの配置テストにはchezmoi、Zshプラグインの検証にはZshとSheldonが必要です。
不足するツールがある場合は該当テストがskipされるため、結果のskip件数も確認します。

`.rubocop.yml`はShopifyの規約を基にし、拡張子のないRubyスクリプトも検査します。
SolargraphはGemfileの依存関係と`.solargraph.yml`を使います。
`.bundle/`と`build/`はローカル専用で、Git管理には含めません。

## SpinelによるAOT

SpinelとCコンパイラーがある環境で、次のコマンドを使います。

```sh
bundle exec rake aot       # 3スクリプトをbuild/へコンパイル
bundle exec rake test:aot  # ビルド後、公開コマンドをバイナリへ切り替えてテスト
```

`scripts/`内のコマンドは、通常どおりRubyで実行します。AOT版を使う場合は`build/setup-zsh`、
`build/update-zsh-plugins`、`build/nvim-experiment`を明示的に実行します。
`setup-zsh`の処理順をメソッド単位で差し替えるテストは、AOT検証時もCRubyで実行します。

SpinelではCRubyのすべてのAPIが同じように動くとは限りません。手元の
`2026.10.25+2383 (c1d162f68)`では、環境変数のHashを先頭引数に渡す`exec`が実行時に失敗しました。
ランチャーは環境変数を設定してから`exec`する形にしています。

`__dir__`からリポジトリ内の設定や検証スクリプトを参照するため、ビルドはソースの絶対パスを使います。
リポジトリを移動した場合やソースを変更した場合は再ビルドしてください。
`setup-zsh`は内部でRuby版の`scripts/update-zsh-plugins`を呼ぶため、AOT版でもその処理にはRubyが必要です。
バイナリのインストールやchezmoiの適用時の自動ビルドは行いません。

Spinelの対応範囲は[公式ドキュメント](https://github.com/matz/spinel/blob/master/docs/limitations.md)も参照してください。

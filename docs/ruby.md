# Rubyスクリプトの開発

開発用gemはGemfileで管理します。スクリプト自体はRuby標準ライブラリだけで動きます。

```sh
bundle install
bundle exec rake test
bundle exec rubocop --cache false
```

テストはMinitestです。仮ホームとダミーコマンドを使い、実環境へのパッケージ導入・ログインシェル変更・プラグイン取得は行いません。
配置テストにはchezmoi、Zshプラグインの検証にはZshとSheldonが必要です。
不足するツールがある場合は該当テストがskipされるため、結果のskip件数も確認します。

RuboCopはShopifyの規約を基にします。SolargraphはGemfileと`.solargraph.yml`を使います。
`.bundle/`はローカル専用で、Git管理には含めません。

## AOTの調査メモ

Spinel `2026.10.25+2383 (c1d162f68)`で3スクリプトのコンパイルとテストは成功しました。
ただし、環境変数のHashを渡す`exec`は実行時に失敗し、書き換えが必要でした。
外部コマンドの実行が中心のため、保守対象を増やさず通常のRubyで実行します。

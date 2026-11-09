# NeovimでRubyを書く

通常のLazyVimではRuby Extraを有効にし、言語サーバーにSolargraphを使います。
補完・定義への移動・診断はSolargraph、保存時の整形はRuboCopが担当します。
Ruby LSPとRuboCopの単独LSPはRuby Extraが無効にし、診断の重複を避けます。

## 起動と確認

プロジェクトのディレクトリで起動します。Rubyの選択が不安定ならmiseを明示します。

```sh
mise exec -- nvim script.rb
```

`:Mason`で`solargraph`と`rubocop`の導入状態、Rubyファイルを開いて`:LspInfo`で
`solargraph`の接続を確認します。設定変更後はNeovimを起動し直します。
補完の手動表示は挿入モードで`Ctrl+Space`、整形は`Space c f`です。

## 静的解析

Solargraphの型チェックはプロジェクトごとの`.solargraph.yml`で有効にします。
このリポジトリでは次のreporterを使います。別のプロジェクトでも必要に応じて設定します。
既存の設定がある場合はreporterを追加します。

```yaml
reporters:
  - rubocop
  - typecheck:strict
```

`strict`は引数の数とメソッド呼び出しを検査しますが、推論できないコードにも警告が出ます。
必要な箇所にYARDの`@param`・`@return`で型を補います。動的に定義されるメソッドや
外部ライブラリの型まで完全に検査できるわけではありません。

参照: [Solargraphの型チェック](https://solargraph.org/guides/type-checking)、
[LazyVimのRuby Extra](https://www.lazyvim.org/extras/lang/ruby)。

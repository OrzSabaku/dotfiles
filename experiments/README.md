# Neovimの実験

`nvim-experiment/init.lua`は以前の自作設定です。通常の導入処理には含めません。
日常の`nvim`は`common/.config/nvim/`のLazyVimを使用します。

```sh
~/dotfiles/scripts/nvim-experiment
~/dotfiles/scripts/nvim-experiment path/to/file
```

専用コマンドは`XDG_CONFIG_HOME`をこのディレクトリ、`NVIM_APPNAME`を`nvim-experiment`にして起動します。
設定はここ、プラグインなどのデータ・状態・キャッシュはnvim-experiment専用になります。
通常のLazyVimの設定・プラグインディレクトリを共有しません。
初回は`vim.pack.add()`で設定内のプラグインを取得します。今回の移行では取得していません。
Neovim 0.12系での利用を想定しています。

これはファイルアクセスを制限するサンドボックスではありません。ホストのファイルや実行ファイルにはアクセスできます。
Neovim本体・LSP・外部ツールごと分けたい場合はDockerなどを使用します。
現在はそのコンテナーを作成・起動していません。
旧`nvim-personal`関数と設定リンクは廃止しました。既に開いているBashでは関数が残る場合があるため、新しいシェルを使ってください。

# Neovimの実験

自作設定を試すためのもの。通常の導入には含めません。
普段の `nvim` は `home/dot_config/nvim/` のLazyVimです。

```sh
~/.local/share/chezmoi/scripts/nvim-experiment.rb
~/.local/share/chezmoi/scripts/nvim-experiment.rb path/to/file
```

Neovim 0.12系を想定しています。初回起動時は `vim.pack.add()` がプラグインを取得します。

`NVIM_APPNAME=nvim-experiment` と専用の `XDG_CONFIG_HOME` で、設定・データ・状態・キャッシュを分けます。
ホストのファイルやコマンドにはアクセスできます。Dockerでの隔離環境はまだ作っていません。

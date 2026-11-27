# 実験用設定

通常の導入対象に含めない設定の置き場です．普段の `nvim` は `home/dot_config/nvim/` のLazyVimを使います．

## Neovimの実験

```sh
mise run --skip-tools nvim-experiment
mise run --skip-tools nvim-experiment -- path/to/file
```

- Neovim 0.12系を想定しています．初回起動時は `vim.pack.add()` がプラグインを取得します．
- `--skip-tools` で起動時のツール自動導入を抑えます．
- chezmoiで配置したグローバルタスクを使うため，どのディレクトリからでも呼び出せます．相対パスは呼び出し元を基準にし，管理元を移動した場合は `chezmoi apply` でタスクの参照先を更新します．
- Neovimへ引数を渡す場合は，miseの引数と区別するためタスク名の後に `--` を置きます．
- `NVIM_APPNAME=nvim-experiment` と専用の `XDG_CONFIG_HOME` で設定・データ・状態・キャッシュを分けますが，ホストのファイルやコマンドへのアクセス自体は隔離されません（Dockerでの隔離環境は未作成）．

## そのほかの記録

- `vimrc`・`zprofile.zsh`: 旧Vim設定と歓迎画面用Zprofileの記録です．実環境には導入しません．

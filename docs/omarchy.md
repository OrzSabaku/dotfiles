# Omarchy

<!--toc:start-->
- [Omarchy](#omarchy)
  - [よく触る場所](#よく触る場所)
  - [変更したら](#変更したら)
<!--toc:end-->

Omarchy標準を読み込み、個人設定を追加します。配置対象は [chezmoiの条件設定](../home/.chezmoiignore)で選びます。
`/usr/share/omarchy/`と生成テーマはそのまま使います。

## よく触る場所

| 設定 | ファイル |
| --- | --- |
| 画面の配置・倍率 | [.config/hypr/monitors.lua](../home/dot_config/hypr/monitors.lua) |
| キーボード・マウス | [.config/hypr/input.lua](../home/dot_config/hypr/input.lua) |
| ショートカット | [.config/hypr/bindings.lua](../home/dot_config/hypr/bindings.lua) |
| 枠・余白・アニメーション | [.config/hypr/looknfeel.lua](../home/dot_config/hypr/looknfeel.lua) |
| バー・プラグインの有効化状態 | [.config/omarchy/shell.json](../home/dot_config/omarchy/private_shell.json) |
| Ghosttyの共通操作 | [共通のdotfiles.conf](../home/dot_config/ghostty/dotfiles.conf) |
| 日本語入力・候補表示 | [共通のFcitx5設定](../home/dot_config/fcitx5/) |

外部画面は上、内蔵画面は下。倍率を考慮した論理座標で中央を揃えています。

## 変更したら

`chezmoi diff` → `chezmoi apply` で反映してから確認します。

- Hyprlandは `hyprctl reload` → `hyprctl configerrors` で確認します。
- Ghosttyは `ghostty +validate-config` で検証します。
- シェル設定は新しい端末で確認します。

通知・アイドルのプラグイン本体は別リポジトリで管理します。
更新後は、ロックされていないデスクトップ端末で `omarchy restart shell` が必要です。

詳しくはWikiの[Omarchy](https://github.com/OrzSabaku/dotfiles/wiki/Omarchy)を参照してください。
Fcitx5の管理範囲・再読み込みは[Fcitx5の設定](https://github.com/OrzSabaku/dotfiles/wiki/Input-Method)を参照してください。

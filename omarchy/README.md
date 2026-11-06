# Omarchy

<!--toc:start-->
- [Omarchy](#omarchy)
  - [よく触る場所](#よく触る場所)
  - [変更したら](#変更したら)
<!--toc:end-->

Omarchy標準を読み込み、個人設定を追加します。導入対象は [files.json](files.json)。
`/usr/share/omarchy/`と生成テーマはそのまま使います。

## よく触る場所

| 設定 | ファイル |
| --- | --- |
| 画面の配置・倍率 | [.config/hypr/monitors.lua](.config/hypr/monitors.lua) |
| キーボード・マウス | [.config/hypr/input.lua](.config/hypr/input.lua) |
| ショートカット | [.config/hypr/bindings.lua](.config/hypr/bindings.lua) |
| 枠・余白・アニメーション | [.config/hypr/looknfeel.lua](.config/hypr/looknfeel.lua) |
| バー・プラグインの有効化状態 | [.config/omarchy/shell.json](.config/omarchy/shell.json) |
| Ghosttyの共通操作 | [commonのdotfiles.conf](../common/.config/ghostty/dotfiles.conf) |
| 日本語入力・候補表示 | [commonのFcitx5設定](../common/.config/fcitx5/) |

外部画面は上、内蔵画面は下。倍率を考慮した論理座標で中央を揃えています。

## 変更したら

- Hyprlandは `hyprctl reload` → `hyprctl configerrors` で確認します。
- Ghosttyは `ghostty +validate-config` で検証します。
- シェル設定は新しい端末で確認します。

通知・アイドルのプラグイン本体は別リポジトリで管理します。
更新後は、ロックされていないデスクトップ端末で `omarchy restart shell` が必要です。

詳しくはWiki原稿の[Omarchy](../docs/wiki/Omarchy.md)と[導入・復元](../docs/wiki/Setup.md)へ。
Fcitx5の管理範囲・再読み込みは[Fcitx5の設定](../docs/wiki/Input-Method.md)を参照してください。

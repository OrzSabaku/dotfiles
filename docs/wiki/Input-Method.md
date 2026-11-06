# Fcitx5の設定

Fcitx5の個人設定は`common/.config/fcitx5/`で管理します。
OmarchyとFedoraの両方で、同じ原本へファイル単位でリンクします。

## 管理する設定

| ファイル | 内容 |
| --- | --- |
| `config` | 切り替えキーと起動時の入力状態 |
| `profile` | USキーボードとMozcの登録・順序 |
| `conf/classicui.conf` | 候補表示とテーマ |
| `conf/clipboard.conf` | クリップボード機能のショートカット |
| `conf/pinyin.conf` | クラウド予測を無効にする設定 |
| `conf/quickphrase.conf` | 定型文機能のショートカット |
| `conf/xcb.conf` | XKB設定の上書きを無効にする設定 |

Mozcの設定DB・ユーザー辞書・学習履歴、Fcitx5のデータ・キャッシュ、バックアップは管理しません。
既定値のコメントだけだった`mozc.conf`・`wayland.conf`・`notifications.conf`も実環境に残します。
管理対象を増やす場合は、導入一覧と`.gitignore`の許可リストを両方更新してください。

## 新しい環境へ導入する

Fcitx5とMozcのFcitx5アドオンは、OS側で別途導入します。
Mozc UT版も入力メソッドIDは`mozc`のままです。
現在のテーマ設定に合わせる場合は、`FluentDark`テーマも用意してください。
このdotfilesはパッケージ導入、自動起動、入力メソッド用の環境変数を変更しません。

Fcitx5の設定画面を閉じてから実行します。Omarchyでは次のコマンドを使います。

```sh
cd ~/dotfiles
python3 install.py --profile omarchy --dry-run
python3 install.py --profile omarchy --apply
```

既存設定と内容・権限が違う場合は停止します。差分を確認し、残す設定を原本に反映してから再実行します。
Gitは`600`と`644`の違いを保存しません。権限だけが違う場合も、既存設定の権限を確認して原本側を合わせます。
Fedoraの導入手順は[FedoraのREADME](../../fedora/README.md)を参照してください。

## 設定を変更する

原本を編集した後は、Fcitx5が動いているデスクトップ端末で再読み込みします。

```sh
fcitx5-remote -r
```

設定画面から変更した場合は、`git diff -- common/.config/fcitx5`で内容を確認してください。
あわせて`ls -l ~/.config/fcitx5/config ~/.config/fcitx5/profile ~/.config/fcitx5/conf/`でリンク先を確認します。
通常ファイルに置き換わっていたら、原本と比較して変更を取り込み、導入コマンドで再リンクします。

英語入力で開始する設定は`ActiveByDefault=False`です。
現在はフォーカス変更時の強制リセットを設定していません。
`profile`の`DefaultIM=mozc`は、日本語入力を有効にしたときに使う入力メソッドです。
実際の入力欄で英語・日本語の切り替えと候補表示を確認してください。

## Omarchyで元に戻す

導入時に表示されたバックアップを指定します。復元の前に設定画面を閉じてください。

```sh
python3 install.py --restore <バックアップディレクトリ>
python3 install.py --restore <バックアップディレクトリ> --apply
fcitx5-remote -r
```

導入後に原本を変更している場合は、上書き防止のため復元が停止します。
差分を確認し、元の内容はバックアップ内の保存ファイルから回収してください。

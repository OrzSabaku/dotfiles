# Gitの個人設定と署名

共有設定は `common/.config/git/config` です。
名前・メール・署名鍵・認証ヘルパーは、非管理の `~/.config/git/config.private` から読み込みます。
署名の検証先 `~/.config/git/allowed_signers` も非管理です。両ファイルは権限600にします。

## 新しい環境で用意するもの

`common/.config/git/config.private.example` を `~/.config/git/config.private` へコピーし、
公開用の作者名、GitHubのnoreplyメール、既存SSH鍵の場所を設定します。
例示ファイルは自動導入しません。既存のグローバル設定に個人情報があれば、導入前に分離します。
秘密鍵は別途用意し、dotfilesへコピーしません。

```sh
git config --file ~/.config/git/config.private user.name YOUR_PUBLIC_ALIAS
git config --file ~/.config/git/config.private user.email YOUR_GITHUB_NOREPLY_EMAIL
git config --file ~/.config/git/config.private user.signingkey ~/.ssh/id_ed25519
```

`git config --global` はリンクされた共有原本を書き換えるため、個人情報の保存には使いません。
GitHub CLIの認証ヘルパーを設定し直す場合も、書き込み先を指定します。

```sh
GIT_CONFIG_GLOBAL="$HOME/.config/git/config.private" gh auth setup-git
```

## SSH署名を検証する

`allowed_signers` に `メールアドレス 鍵種別 公開鍵本体` の形式で登録し、
`config.private` の `gpg.ssh.allowedSignersFile` で指定します。
通常の `git commit` は自動で署名します。検証は `git verify-commit <コミット>` です。
鍵や作者情報が未設定なら署名は失敗します。無署名へ自動で切り替えません。

GitHubでVerifiedと表示するには、公開鍵を署名用として登録します。
認証用の登録とは用途が異なります。登録済みなら重複追加しません。

```sh
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "Git commit signing"
```

登録方法は[GitHubの説明](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key)を参照します。
名前・メールの変更は以後のコミットに適用します。
公開前には、過去の履歴にある作者情報も確認します。

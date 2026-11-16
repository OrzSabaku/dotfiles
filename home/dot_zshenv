# 非対話シェルでも必要なOmarchy標準のPATH設定だけを読み込む。
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# 非対話シェルでもmiseの選択を使い、システム版Rubyとの混在を防ぐ。
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
  typeset -U path
fi

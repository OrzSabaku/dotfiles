# Omarchy PATH and mise shims, including non-interactive SSH commands.
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

exists() {
  local command="${1}"

  if ! (( ${+commands[$command]} )); then
    echo "Error: ${command} がインストールされていません。" >&2
    return 1
  fi
}

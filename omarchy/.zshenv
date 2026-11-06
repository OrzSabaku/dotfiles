# Omarchy PATH and mise shims, including non-interactive SSH commands.
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

exists() {
  local command="${1}"

  if ! (( ${+commands[$command]} )); then
    echo "Error: ${command} がインストールされていません。" >&2
    return 1
  fi
}

# from https://yazi-rs.github.io/docs/quick-start/#shell-wrapper
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

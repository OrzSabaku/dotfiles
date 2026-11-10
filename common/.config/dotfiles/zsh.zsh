[[ -r "$HOME/.config/dotfiles/env.sh" ]] && source "$HOME/.config/dotfiles/env.sh"

# 個人用コマンドの検索パスはここで管理する。
path=("$HOME/.local/bin" $path)
fpath+=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions")

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt EXTENDED_HISTORY

# cd
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CDABLE_VARS
# glob
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NUMERIC_GLOB_SORT
# prompts
setopt PROMPT_SUBST
setopt INTERACTIVE_COMMENTS

# complete
setopt CORRECT
setopt AUTO_LIST
setopt NO_BEEP
setopt NO_CLOBBER
setopt NO_NOMATCH

# keybind
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^P" up-line-or-beginning-search
bindkey "^N" down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Tools

if command -v mise >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi
if command -v starship >/dev/null 2>&1; then eval "$(starship init zsh)"; fi
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh)"; fi
# Use the last validated source. Plugin downloads/updates are explicit so a
# network or upstream failure cannot break every newly opened terminal.
() {
  local plugin_source=''
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/sheldon.zsh"
  if [[ -r "$cache" ]]; then
    plugin_source=$(<"$cache")
  elif command -v sheldon >/dev/null 2>&1; then
    plugin_source=$(sheldon source) || plugin_source=''
  fi
  # 旧キャッシュも、現在と同じ補完初期化を一度だけ実行する。
  if [[ "$plugin_source" != *'# dotfiles: managed-compinit'* ]]; then
    source "$HOME/.config/sheldon/completion-init.zsh"
  fi
  eval "$plugin_source"
}
if command -v gh >/dev/null 2>&1; then eval "$(gh completion -s zsh)"; fi

# Atuinはfzfなどの履歴キーバインドを初期化した後に読み込む。
[[ -r "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
if command -v atuin >/dev/null 2>&1; then eval "$(atuin init zsh)"; fi

# ツールがPATHを追加した後で、重複を取り除く。
typeset -U path fpath

# コマンドを実行する前に、インストール済みか確認する。
exists() {
  local command="$1"
  if ! (( ${+commands[$command]} )); then
    print -u2 -- "Error: ${command} がインストールされていません。"
    return 1
  fi
}

# Yaziで最後に開いていたディレクトリへ移動する。
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

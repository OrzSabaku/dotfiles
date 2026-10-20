# setopt - enable an option
# unsetopt - disable an option
# bindkey - bind a function to a keysequence
# zle - ZLE stands for Zsh Line Editor. Resister function to zle.
# zstyle - inject value to contex pattern to define appearance and behavior, for example comsys (complement system)
# autoload - mark functions specified in fpath and load it when it is called first time.
# zmodload - load zsh binary module to memory
# alias - assign an alias.
# hash - cache a path, define named dir


[[ -r "$HOME/.config/dotfiles/env.sh" ]] && source "$HOME/.config/dotfiles/env.sh"

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
# compinit & zstyle
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' format '%B%F{yellow}--- %d ---%f%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

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
if command -v fzf >/dev/null 2>&1; then source <(fzf --zsh); fi
# Use the last validated source. Plugin downloads/updates are explicit so a
# network or upstream failure cannot break every newly opened terminal.
if command -v sheldon >/dev/null 2>&1; then
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/sheldon.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/sheldon.zsh"
  else
    eval "$(sheldon source)"
  fi
fi
if command -v gh >/dev/null 2>&1; then eval "$(gh completion -s zsh)"; fi

# Unity CLI
case ":${PATH}:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

typeset -U path
path=(
   $path
)

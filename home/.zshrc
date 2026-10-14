# setopt - enable an option
# unsetopt - disable an option
# bindkey - bind a function to a keysequence
# zle - ZLE stands for Zsh Line Editor. Resister function to zle.
# zstyle - inject value to contex pattern to define appearance and behavior, for example comsys (complement system)
# autoload - mark functions specified in fpath and load it when it is called first time.
# zmodload - load zsh binary module to memory
# alias - assign an alias.
# hash - cache a path, define named dir


export LANG="ja_JP.UTF-8"
export EDITOR="nvim"

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# history
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
# cd
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CDABLE_VARS
setopt EXTENDED_HISTORY
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
# The system completion directory contains a duplicate _code file with a
# semicolon in its name.  A generated dump evaluates that name as a command.
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

eval "$("$HOME/.local/bin/mise" activate zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)
eval "$(sheldon source)"

# Unity CLI
case ":${PATH}:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# fzf, bat output style
export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"
export BAT_THEME="base16"
export BAT_STYLE="full"

typeset -U path
path=(
   $path
)

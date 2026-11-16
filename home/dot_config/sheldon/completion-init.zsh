# Initialize completion after all completion paths have been registered.
autoload -Uz compinit
compinit
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi
# fzf-tabが候補選択を担当するため、標準の選択メニューは使わない。
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Initialize completion after all completion paths have been registered.
autoload -Uz compinit
compinit
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Selected Oh My Zsh dependencies and aliases; $1 is its repository directory.
() {
    local omz_dir=$1
    autoload -Uz is-at-least
    zmodload zsh/parameter
    zstyle ':omz:alpha:lib:git' async-prompt no
    source "$omz_dir/lib/clipboard.zsh"
    source "$omz_dir/lib/git.zsh"
    # Retire the old Omarchy Git shortcuts; upstream names now take precedence.
    unalias g gcm gcam gcad 2>/dev/null || true
    source "$omz_dir/plugins/git/git.plugin.zsh"
    if (( $+commands[docker] )); then
        typeset -g ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/ohmyzsh"
        mkdir -p "$ZSH_CACHE_DIR/completions"
        fpath=("$ZSH_CACHE_DIR/completions" $fpath)
        source "$omz_dir/plugins/docker/docker.plugin.zsh"
        source "$omz_dir/plugins/docker-compose/docker-compose.plugin.zsh"
    fi
    # In particular, upstream gwip explicitly disables signing. Remove that and
    # any future alias with the same opt-out rather than overriding Git itself.
    () {
        local shortcut definition
        for shortcut in ${(k)aliases}; do
            definition=${(L)aliases[$shortcut]}
            case "$definition" in
                *--no-gpg-sign*|*commit.gpgsign=false*|*commit.gpgsign=0*)
                    unalias "$shortcut"
                    ;;
            esac
        done
    }
} "$1"

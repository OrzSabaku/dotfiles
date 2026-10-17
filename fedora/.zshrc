# Fedora-specific locale and user-installed tools.
export LANG=ja_JP.UTF-8
case ":$PATH:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
[[ -r "$HOME/.config/dotfiles/zsh.zsh" ]] && source "$HOME/.config/dotfiles/zsh.zsh"

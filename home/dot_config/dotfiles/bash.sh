# Personal interactive Bash settings; tool initialization belongs to the OS.
[[ -r "$HOME/.config/dotfiles/env.sh" ]] && source "$HOME/.config/dotfiles/env.sh"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

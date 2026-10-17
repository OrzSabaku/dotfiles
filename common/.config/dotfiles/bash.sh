# Personal interactive settings; tool initialization belongs to the OS profile.
export EDITOR=nvim
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers --line-range :500 {}'"
export BAT_THEME=base16
export BAT_STYLE=full
# Try the personal Neovim config without replacing Omarchy's LazyVim.
nvim-personal() { NVIM_APPNAME=nvim-personal command nvim "$@"; }

# Preserve Omarchy's portable environment and aliases, but not Bash-only rc.
: ${OMARCHY_PATH:=/usr/share/omarchy}
[[ -r "$OMARCHY_PATH/default/bash/envs" ]] && source "$OMARCHY_PATH/default/bash/envs"
[[ -r "$OMARCHY_PATH/default/bash/aliases" ]] && source "$OMARCHY_PATH/default/bash/aliases"

# Shared completions, keybindings, prompt, tool integration and plugins.
[[ -r "$HOME/.config/dotfiles/zsh.zsh" ]] && source "$HOME/.config/dotfiles/zsh.zsh"

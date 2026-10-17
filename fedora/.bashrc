# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
# Interactive personal preferences; Fedora initialization stays above.
if [[ $- == *i* ]]; then
    [[ -r "$HOME/.config/dotfiles/bash.sh" ]] && source "$HOME/.config/dotfiles/bash.sh"
    if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate bash)"
    elif [[ -x "$HOME/.local/bin/mise" ]]; then
        eval "$("$HOME/.local/bin/mise" activate bash)"
    fi
fi

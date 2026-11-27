# Run with zsh -f -i; caller isolates ZDOTDIR and supplies a temporary directory.
setopt ERR_EXIT
work=$2
# zsh.zshと同じ関数スコープで読み，typesetによるローカル化も検証する．
() {
  local plugin_source=$(<"$1")
  eval "$plugin_source"
} "$1"
# 生成済みの補完がcompinitより前に登録されたことを，実際の対応表で確認する．
if [[ -n ${DOTFILES_ZSH_COMPLETIONS:-} ]]; then
  for completion_file in "$DOTFILES_ZSH_COMPLETIONS"/_*(N); do
    completion_name=${completion_file:t}
    command_name=${completion_name#_}
    [[ ${_comps[$command_name]:-} == "$completion_name" ]] || {
      print -u2 -- "Missing generated completion: $command_name"; exit 1
    }
  done
  for completion_file in "$DOTFILES_ZSH_COMPLETIONS"/*.zsh(N); do
    command_name=${${completion_file:t}%.zsh}
    [[ -n ${_comps[$command_name]:-} ]] || {
      print -u2 -- "Missing sourced completion: $command_name"; exit 1
    }
  done
fi
# Check upstream's actual widget function, not the nonexistent _fzf_tab.
for required in compdef fzf-tab-complete globalias _zsh_highlight; do
  (( ${+functions[$required]} )) || {
    print -u2 "Missing plugin function: $required"; exit 1
  }
done
[[ -n ${FAST_HIGHLIGHT_VERSION:-} ]] || {
  print -u2 'fast-syntax-highlighting did not initialize'; exit 1
}
(( $+widgets[fzf-history-widget] )) || { print -u2 'Missing fzf history widget'; exit 1; }
[[ ${fpath[(r)*/zsh-completions/src]} != '' ]] || {
  print -u2 'Missing zsh-completions path'; exit 1
}
zmodload zsh/parameter
for shortcut in g ga gst gd gcmsg gcm; do
  (( ${+aliases[$shortcut]} )) || { print -u2 "Missing Git alias: $shortcut"; exit 1; }
done
(( ! ${+aliases[gcad]} )) || { print -u2 'Retired gcad alias still exists'; exit 1; }
(( ${+functions[git_current_branch]} && ${+functions[git_main_branch]} && ${+functions[clipcopy]} )) || exit 1
if (( $+commands[docker] )); then
  for shortcut in dps dlo dxcit dcupd dclf dce; do
    (( ${+aliases[$shortcut]} )) || { print -u2 "Missing Docker alias: $shortcut"; exit 1; }
  done
fi
# Exercise an ordinary plugin commit alias against the real global signing setup.
git init --quiet "$work/signing-test"
builtin cd "$work/signing-test"
[[ $(git config --bool commit.gpgsign) == true ]] || { print -u2 'Automatic commit signing is not enabled'; exit 1; }
eval 'gcmsg "Verify alias commit signing" --allow-empty' >/dev/null
git verify-commit HEAD >/dev/null 2>&1 || { print -u2 'Plugin commit signature verification failed'; exit 1; }
print -r -- 'Git/Docker aliases and signed gcmsg commit verified.'

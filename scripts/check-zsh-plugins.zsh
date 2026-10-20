# Run with zsh -f -i; caller isolates ZDOTDIR and supplies a temporary directory.
setopt ERR_EXIT
work=$2
source "$1"
(( ${+functions[compdef]} && ${+functions[_fzf_tab]} && ${+functions[_zsh_highlight]} )) || {
  print -u2 'Missing completion, fzf-tab or fast-syntax-highlighting functions'; exit 1
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
for definition in "${(@v)aliases}"; do
  case "${(L)definition}" in
    *--no-gpg-sign*|*commit.gpgsign=false*|*commit.gpgsign=0*)
      print -u2 'An alias disables commit signing'; exit 1 ;;
  esac
done
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

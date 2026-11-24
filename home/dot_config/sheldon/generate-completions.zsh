# 更新時だけ実行する。出力先は未公開の世代なので、失敗時に以前の補完を壊さない。
setopt ERR_EXIT NO_UNSET
destination=$1

generate() {
    # _名前はfpath用、名前.zshはcompinit後にsourceする補完。
    local filename=$1
    shift
    # 未導入のCLIは省略する。導入済みCLIの生成失敗は更新全体を中止する。
    if (( $+commands[$1] )); then
        "$@" > "$destination/$filename"
        [[ -s "$destination/$filename" ]] || {
            print -u2 -- "Empty completion output: $filename"
            return 1
        }
        zsh -n "$destination/$filename"
    fi
    return 0
}

generate _gh gh completion -s zsh
generate _chezmoi chezmoi completion zsh
generate _herdr herdr completion zsh
generate _mise mise completion zsh
generate _sheldon sheldon completions --shell zsh
generate _starship starship completions zsh
generate _atuin atuin gen-completions --shell zsh
generate _buf buf completion zsh
generate _codex codex completion zsh
generate _uv uv generate-shell-completion zsh
generate _uvx uvx --generate-shell-completion zsh
generate _rustup rustup completions zsh
generate _cargo rustup completions zsh cargo
generate opencode.zsh opencode completion
generate lazygit.zsh lazygit completion zsh

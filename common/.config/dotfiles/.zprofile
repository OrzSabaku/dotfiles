align_center() {
  local message="${1:-Ghostty}"
  local font="${2:-letter}"
  local filter="${3:-rainbow}"

  if ! (( ${+command[toilet]} )); then
    echo "Error: toilet がインストールされていません。" >&2
    return 1
  fi

  local cmd=(toilet -f "$font")
  [[ -n "$filter" ]] && cmd+=(-F "$filter")

  local text
  text=$("${cmd[@]}" "$message") || return 1

  # テキストの行数・最大幅を取得
  # ANSIエスケープシーケンスを除外して計算する
  local lines_count max_len=0 clean_line
  lines_count=$(echo -n "$text" | grep -c '^')

  while IFS= read -r line; do
    clean_line=$(echo -n "$line" | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g')
    (( ${#clean_line} > max_len )) && max_len=${#clean_line}
  done <<< "$text"

  #  ターミナルサイズと開始位置の計算
  local term_lines term_cols start_line start_col
  term_lines=$(tput lines)
  term_cols=$(tput cols)

  start_line=$(( (term_lines - lines_count) / 2 ))
  start_col=$(( (term_cols - max_len) / 2 ))

  (( start_line < 0 )) && start_line=0
  (( start_col < 0 )) && start_col=0

  # 描画
  clear

  local current_line=$start_line
  while IFS= read -r line; do
    tput cup $current_line $start_col
    printf "%s\n" "$line"
    (( current_line++ ))
  done <<< "$text"

  tput cup $term_lines 0
}

username=$USER
align_center "WELCOME BOARD, ${(U)username}" pagga

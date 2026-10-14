" --- 基本表示・操作設定 ---
set nocompatible
set number          " 行番号を表示
" set cursorline      " 現在の行をハイライト
set showmatch       " 閉じ括弧の入力時に対応する括弧を強調
syntax on           " 構文ハイライトを有効化

" --- 検索設定 ---
set ignorecase      " 検索時に大文字小文字を区別しない
set smartcase       " 大文字が含まれる場合は区別する
set hlsearch        " 検索結果をハイライト
set incsearch       " インクリサーチを有効化

" --- インデント設定 ---
set tabstop=4       " タブ幅をスペース4つ分にする
set shiftwidth=4    " 自動インデント時のズレ幅
set expandtab       " タブ入力をスペースに変換
set autoindent      " 改行時に前の行のインデントを継続
set smartindent     " C言語ライクな自動インデント

" --- Fedora・文字コード設定 ---
set encoding=utf-8  " 内部文字コード
set fileencodings=utf-8,euc-jp,sjis,cp932 " 読み込み文字コード候補
set fileformats=unix,dos,mac " 改行コードの自動認識

" --- クリップボード連携 ---
" Fedoraのシステムクリップボードとヤンク（コピー）を共有
set clipboard+=unnamedplus

" --- バックアップ・その他 ---
set nobackup        " バックアップファイル（~）を作らない
set noswapfile      " スワップファイル（.swp）を作らない
set backspace=indent,eol,start " バックスペースでインデントや改行を消せるようにする

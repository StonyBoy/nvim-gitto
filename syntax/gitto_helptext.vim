" Steen Hegelund
" Time-Stamp: 2022-Mar-06 14:42
" Syntax for Git log listings

syntax match xHelpKey /\v^  \- [^:]+:/
syntax region xHelpText start=/\v^(\=\=){30}/ end=/\v(\=\=){30}$/ contains=xHelpKey

highlight link xHelpText Comment
highlight link xHelpKey Macro


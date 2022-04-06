" Steen Hegelund
" Time-Stamp: 2022-Mar-06 18:45
" Syntax for Git Commit Diff listings

syntax clear
setlocal nospell

syntax match xSep /\t/ contained
syntax match xFileAdditions /\v^\d+/ contained
syntax match xFileRemovals /\v\t\d+/ contained
syntax match xFilePath /\v\S+$/ contained

syntax match xFileItemLine /^\d.*$/ contains=xSep,xFileAdditions,xFileRemovals,xFilePath

highlight link xFilePath Function
highlight link xFileAdditions Statement
highlight link xFileRemovals Include
highlight link xFileItemLine Comment

" Get the path of this syntax file (even with symlinks) and 
" load the nearby helptext syntax file
let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source ' . s:path . '/gitto_helptext.vim'

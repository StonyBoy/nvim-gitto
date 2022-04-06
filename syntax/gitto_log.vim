" Steen Hegelund
" Time-Stamp: 2022-Mar-06 14:45
" Syntax for Git log listings

syntax clear
setlocal nospell

syntax match xCommitRef /\v^[^|]+$/
syntax match xSep / [|] / contained
syntax match xCommitId /\v[0-9a-f]{6,}/ contained
syntax match xCommitDate /\v\d{4}-\d{2}-\d{2}/ contained
syntax match xSubject /\v[^|]+$/ contained
syntax match xCommitLine /\v^ .*$/ contains=xSep,xCommitId,xCommitDate,xSubject

highlight link xCommitRef Function
highlight link xCommitId Number
highlight link xCommitDate Include
highlight link xSubject Statement

" Get the path of this syntax file (even with symlinks) and 
" load the nearby helptext syntax file
let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source ' . s:path . '/gitto_helptext.vim'

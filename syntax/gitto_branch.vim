" Steen Hegelund
" Time-Stamp: 2022-Mar-06 14:45
" Syntax for Git branch listings

syntax clear
setlocal nospell

syntax match xCurrent /\v^\* /
syntax match xCommitRef /\vrefs\S+/
syntax match xRemoteCommitRef /\vrefs\/remote\S+/
syntax match xCommitId /\v[0-9a-f]{10,}/
syntax match xWorktree /\v\/\S+/
syntax match xSubject /\v[^|]+$/

highlight link xCurrent Include
highlight link xRemoteCommitRef Comment
highlight link xCommitRef Function
highlight link xCommitId Number
highlight link xWorktree Include
highlight link xSubject Statement

" Get the path of this syntax file (even with symlinks) and 
" load the nearby helptext syntax file
let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
execute 'source ' . s:path . '/gitto_helptext.vim'

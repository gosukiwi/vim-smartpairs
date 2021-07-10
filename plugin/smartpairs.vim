" smartpairs.vim - Sensible pairings
" Maintainer:	Federico Ramirez <fedra.arg@gmail.com>
" Version: 0.0.1
" Repository: https://github.com/gosukiwi/smartpairs

if exists('g:smartpairs_loaded')
  finish
endif

let g:smartpairs_loaded = 1
let g:smartpairs_default_pairs = { 
      \ '(': ')',
      \ '[': ']',
      \ '{': '}',
      \ '"': '"',
      \ "'": "'",
      \ }
let g:smartpairs_pairs = {}
let g:smartpairs_pairs['vim'] = { '(': ')', '[': ']', '{': '}', "'": "'" }
let g:smartpairs_pairs['javascript'] = { '(': ')', '[': ']', '{': '}', '"': '"', "'": "'", '`': '`' }

" KEYBINDED FUNCTIONS
" ==============================================================================
function! s:Jump(char) abort
  let nextchar = getline('.')[col('.') - 1]

  if nextchar == a:char
    return "\<Right>"
  else
    return a:char
  endif
endfunction

function! s:InsertOrJump(open, close) abort
  let prevchar = getline('.')[col('.') - 2]
  " We want to always return the actual value if we are trying to escape
  " somehting
  if prevchar == '\' | return a:open | endif

  let jump = s:Jump(a:open)
  if jump != a:open | return jump | endif

  " Jump failed, we are adding now. When the opening and closing pairs are the
  " same ('', "", ``, etc), we don't want to expand if the previous character
  " is not empty. That is the way most IDEs behave.
  if (prevchar !~ '\s' && prevchar != '') && a:open == a:close
    return a:open
  else
    return a:open . a:close . "\<Left>"
  endif
endfunction

function! s:Backspace() abort
  let prevchar = getline('.')[col('.') - 2]
  let remaining = getline('.')[col('.') - 1:]

  if has_key(s:smartpairs_pairs, prevchar) && remaining =~ '^\s*' . s:smartpairs_pairs[prevchar]
    return "\<Left>\<C-O>df" . s:smartpairs_pairs[prevchar]
  else
    return "\<BS>"
  endif
endfunction

function! s:Space() abort
  let prevchar = getline('.')[col('.') - 2]
  let nextchar = getline('.')[col('.') - 1]

  if has_key(s:smartpairs_pairs, prevchar) && nextchar == s:smartpairs_pairs[prevchar]
    return "\<Space>\<Space>\<Left>"
  else
    return "\<Space>"
  endif
endfunction

function! s:CarriageReturn() abort
  let prevchar = getline('.')[col('.') - 2]
  let nextchar = getline('.')[col('.') - 1]

  if has_key(s:smartpairs_pairs, prevchar) && nextchar == s:smartpairs_pairs[prevchar]
    return "\<CR>\<C-O>O"
  else
    return "\<CR>\<Plug>(smartpairs-old-cr)"
  endif
endfunction

" INITIALIZATION
" ==============================================================================
function! s:SetUpMappings() abort
  let keys = keys(s:smartpairs_pairs)
  for opening in keys
    execute 'inoremap <expr> <buffer> <silent> ' . opening . ' <SID>InsertOrJump("' . escape(opening, '"') . '", "' . escape(s:smartpairs_pairs[opening], '"') . '")'
    if opening != s:smartpairs_pairs[opening]
      execute 'inoremap <expr> <buffer> <silent> ' . s:smartpairs_pairs[opening] . ' <SID>Jump("' . escape(s:smartpairs_pairs[opening], '"') . '")'
    endif
  endfor

  inoremap <expr> <buffer> <silent> <BS> <SID>Backspace()
  inoremap <expr> <buffer> <silent> <Space> <SID>Space()

  if s:smartpairs_hijack_return
    " Here we check for previous mappings to |<CR>|. If found, we try to keep
    " their functionality as much as possible.
    "
    " If the previous mapping starts with |<CR>|, it will remove that part of
    " the mapping and add it later on. This is because Vim will make an
    " infinite loop when that's the case.
    let s:old_cr_mapping = maparg('<CR>', 'i', 0, 1)
    if s:old_cr_mapping != {}
      let s:old_cr = s:old_cr_mapping.rhs
      let s:old_cr = substitute(s:old_cr, '^<CR>', '', 'g')
      let s:old_cr = substitute(s:old_cr, '<SID>', '<SNR>' . s:old_cr_mapping.sid . '_', 'g')
      let s:old_cr = substitute(s:old_cr, '<Plug>', '<SNR>' . s:old_cr_mapping.sid . '_', 'g')
      execute 'imap <buffer> <Plug>(smartpairs-old-cr) ' . s:old_cr
    else
      execute 'inoremap <buffer> <Plug>(smartpairs-old-cr) <Nop>'
    endif

    imap <expr> <buffer> <CR> <SID>CarriageReturn()
  endif
endfunction

function! SmartPairsInitialize() abort
  let s:smartpairs_pairs = has_key(g:smartpairs_pairs, &filetype) ? g:smartpairs_pairs[&filetype] : g:smartpairs_default_pairs
  let s:smartpairs_hijack_return = exists('g:smartpairs_hijack_return') ? g:smartpairs_hijack_return : 1

  call s:SetUpMappings()
endfunction

autocmd BufEnter * :call SmartPairsInitialize()

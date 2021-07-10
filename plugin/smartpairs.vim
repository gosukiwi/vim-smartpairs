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

" UTILITY FUNCTIONS
function! s:IsSpaceOrEmpty(char) abort
  return a:char == '' || a:char =~ '\s'
endfunction

" Symmetric pairs, such as "" and '' behave differently when deleting. We want
" to be more conservative. So it will only delete if they are surrounded by
" spaces or nothing.
"
" Eg:
"
"     ''_'  -> deleting will cause ->  '_'
"     '''_  -> deleting will cause ->  ''_
"     '_'   -> deleting will cause ->  _

function! s:BackspaceForSymmetricPairs(prevchar)
  let nextchar = getline('.')[col('.') - 1]
  if nextchar != s:smartpairs_pairs[a:prevchar] | return "\<BS>" | endif

  let prevprevchar = getline('.')[col('.') - 3]
  if !s:IsSpaceOrEmpty(prevprevchar) | return "\<BS>" | endif

  let nextnextchar = getline('.')[col('.')]
  if !s:IsSpaceOrEmpty(nextnextchar) | return "\<BS>" | endif

  return "\<Right>\<BS>\<BS>"
endfunction

" Asymmetric pairs are simpler. We just delete them if they match.
function! s:BackspaceForAsymmetricPairs(prevchar)
  let nextchar = getline('.')[col('.') - 1]
  if nextchar == s:smartpairs_pairs[a:prevchar]
    return "\<Right>\<BS>\<BS>"
  else
    return "\<BS>"
  endif
endfunction

" KEYBINDED FUNCTIONS
" ==============================================================================
function! s:Jump(char) abort
  if s:smartpairs_jumps_enabled == 0 | return a:char | endif

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

  " Jump failed, we are adding now. When the pair is SYMMETRIC ('', "", ``,
  " etc), we don't want to expand if the previous character is not empty.
  if (prevchar !~ '\s' && prevchar != '') && a:open == a:close
    return a:open
  else
    return a:open . a:close . "\<Left>"
  endif
endfunction

function! s:Backspace() abort
  let prevchar = getline('.')[col('.') - 2]
  if !has_key(s:smartpairs_pairs, prevchar) | return "\<BS>" | endif

  if prevchar == s:smartpairs_pairs[prevchar]
    return s:BackspaceForSymmetricPairs(prevchar)
  else
    return s:BackspaceForAsymmetricPairs(prevchar)
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

  if s:smartpairs_hijack_backspace
    inoremap <expr> <buffer> <silent> <BS> <SID>Backspace()
  endif

  if s:smartpairs_hijack_space
    inoremap <expr> <buffer> <silent> <Space> <SID>Space()
  endif

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
  let s:smartpairs_hijack_return = get(g:, 'smartpairs_hijack_return', 1)
  let s:smartpairs_hijack_space = get(g:, 'smartpairs_hijack_space', 1)
  let s:smartpairs_hijack_backspace = get(g:, 'smartpairs_hijack_backspace', 1)
  let s:smartpairs_jumps_enabled = get(g:, 'smartpairs_jumps_enabled', 1)

  call s:SetUpMappings()
endfunction

autocmd BufEnter * :call SmartPairsInitialize()

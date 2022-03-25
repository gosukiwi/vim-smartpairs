" smartpairs.vim - Sensible pairings
" Maintainer:	Federico Ramirez <fedra.arg@gmail.com>
" Version: 0.1.0
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
" to be more conservative. So it will only delete if:
"   - The previous character different from the opening
"   - The previous char is a space or empty
function! s:BackspaceForSymmetricPairs(prevchar)
  let nextchar = getline('.')[col('.') - 1]
  if nextchar != b:smartpairs_pairs[a:prevchar] | return "\<BS>" | endif

  let prevprevchar = getline('.')[col('.') - 3]
  if s:IsSpaceOrEmpty(prevprevchar) || prevprevchar != a:prevchar
    return "\<C-G>U\<Right>\<BS>\<BS>"
  endif

  return "\<BS>"
endfunction

" Asymmetric pairs are simpler. We just delete them if they match.
function! s:BackspaceForAsymmetricPairs(prevchar)
  let nextchar = getline('.')[col('.') - 1]
  if nextchar == b:smartpairs_pairs[a:prevchar]
    return "\<C-G>U\<Right>\<BS>\<BS>"
  else
    return "\<BS>"
  endif
endfunction

" KEYBINDED FUNCTIONS
" ==============================================================================
function! s:Jump(char) abort
  if get(g:, 'smartpairs_jumps_enabled', 1) == 0 | return a:char | endif

  let nextchar = getline('.')[col('.') - 1]
  if nextchar == a:char
    return "\<C-G>U\<Right>"
  else
    return a:char
  endif
endfunction

function! s:InsertOrJump(open, close) abort
  let prevchar = getline('.')[col('.') - 2]
  " We want to always return the actual value if we are trying to escape
  " something
  if prevchar == '\' | return a:open | endif

  let jump = s:Jump(a:open)
  if jump != a:open | return jump | endif

  " Jump failed, we are inserting now.
  " If the next char is a word, don't expand
  let nextchar = getline('.')[col('.') - 1]
  if nextchar =~ '\w'
    return a:open
  endif

  " If pair is ASYMMETRIC, just return expansion
  if a:open != a:close
    return a:open . a:close . "\<C-G>U\<Left>"
  endif

  " When the pair is SYMMETRIC. We want to expand if:
  "   - The previous character different from the opening AND is word
  "   - The previous char is a space or empty
  if (a:open != prevchar && prevchar !~ '\w') || s:IsSpaceOrEmpty(prevchar)
    return a:open . a:close . "\<C-G>U\<Left>"
  else
    return a:open
  endif
endfunction

function! s:Backspace() abort
  if !exists('b:smartpairs_pairs') | return "\<BS>" | endif

  let prevchar = getline('.')[col('.') - 2]
  if !has_key(b:smartpairs_pairs, prevchar) | return "\<BS>" | endif

  if prevchar == b:smartpairs_pairs[prevchar]
    return s:BackspaceForSymmetricPairs(prevchar)
  else
    return s:BackspaceForAsymmetricPairs(prevchar)
  endif
endfunction

function! s:CarriageReturn() abort
  if !exists('b:smartpairs_pairs') | return "\<CR>" | endif

  let prevchar = getline('.')[col('.') - 2]
  let nextchar = getline('.')[col('.') - 1]

  if has_key(b:smartpairs_pairs, prevchar) && nextchar == b:smartpairs_pairs[prevchar]
    return "\<CR>\<C-O>O"
  else
    return "\<CR>"
  endif
endfunction

" INITIALIZATION
" ==============================================================================
function! s:SetUpMappings() abort
  let keys = keys(b:smartpairs_pairs)
  for opening in keys
    execute 'inoremap <script><expr><buffer><silent> ' . opening . ' <SID>InsertOrJump("' . escape(opening, '"') . '", "' . escape(b:smartpairs_pairs[opening], '"') . '")'
    if opening != b:smartpairs_pairs[opening]
      execute 'inoremap <script><expr><buffer><silent> ' . b:smartpairs_pairs[opening] . ' <SID>Jump("' . escape(b:smartpairs_pairs[opening], '"') . '")'
    endif
  endfor
endfunction

function! SmartPairsInitialize() abort
  if get(b:, 'smartpairs_mappings_initialize', 0) == 0
    let b:smartpairs_mappings_initialize = 1
    let b:smartpairs_pairs = has_key(g:smartpairs_pairs, &filetype) ? g:smartpairs_pairs[&filetype] : g:smartpairs_default_pairs
    call s:SetUpMappings()
  end
endfunction

autocmd FileType * :call SmartPairsInitialize()

if get(g:, 'smartpairs_hijack_return', 1)
  imap <script><expr> <CR> <SID>CarriageReturn()
endif

if get(g:, 'smartpairs_hijack_backspace', 1)
  imap <script><expr><silent> <BS> <SID>Backspace()
endif

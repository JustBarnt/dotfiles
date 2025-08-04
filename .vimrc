let mapleader=" "
let maplocalleader="\\"

set number
set expandtab
set ignorecase
set incsearch
set hlsearch
set smartcase
set virtualedit=block
set backspace=indent,eol,start
set clipboard=unnamed

nnoremap <Esc> :nohlsearch<CR>
nnoremap <silent> gcc :set operatorfunc=ToggleComment<CR>g@

function! ToggleComment(type, ...)
  " Determine the line range based on motion
  if a:type ==# 'line'
    let start = line("'<")
    let end = line("'>")
  elseif a:type ==# 'char'
    let start = line("'<")
    let end = line("'>")
  elseif a:type ==# 'block'
    " Handle blockwise selection differently if needed
    return
  else
    let start = a:1
    let end = a:2
  endif

  " Get the lines in the range
  let lines = getline(start, end)

  " Toggle comment for each line (you would implement your comment logic here)
  let is_comment = 0
  let new_lines = map(lines, 'v:val =~ "^\\s*//" ? substitute(v:val, "^\\s*//\\s*", "", "") : "// ".v:val')

  " Replace lines in the buffer
  call setline(start, new_lines)
endfunction


" Disable compatibility of Vim with Vi.
set nocompatible

" Enable automatic detection of filetypes when opening a file or creating
" a new buffer. Load plugins specific to the type of the file after detection.
filetype plugin on

" Allow to remove text of different categories with the backspace key.
set backspace=indent,eol,start

" Adjust colors to a dark background.
colorscheme default
set background=light
hi Search ctermfg=white ctermbg=black
hi IncSearch ctermfg=yellow ctermbg=black

" Perform case sensitive searches by default.
" Case sensitivity can be disabled by including \C anywhere in a pattern.
set noignorecase

" Show (partial) command in the last line of the screen.
set showcmd

set vb t_vb=

" Increase the number of ex commands be saved in the history from 50 to 200.
set history=200

" Allow hidden buffers without having to add an exclamation mark to commands.
set hidden

" Look into subdirectories recursively when completing filenames with :find.
" If find is used e.g. the home folder the search will be very slow, but in
" project with only few directory levels underneath this can be useful.
set path+=**

" Incremental search.
set incsearch

" Enable highlight search and use backspace to clear search highlighting.
set hlsearch
nnoremap <backspace> :noh<cr>

" Do not beep in case of errors but show an indication of failed command in
" the status line instead.
set visualbell

" Set the terminal type when Vim is started within GNU Screen.
" This is necessary because GNU Screen changes the TERM evironment variable.
if match($TERM, "screen") != -1
  set term=xterm-256color
endif

" Display line numbers in the left margin.
set number
syntax enable

" Show the line and column number of the cursor position.
set ruler

set autoindent

" The number of rows which are used to display the command line.
set cmdheight=1

" Do not split words when breaking up a physical line into multiple display
" lines because the real line is longer than the width of the window.
set linebreak

" Show tabs and trailing spaces at the ends of lines.
set list
set listchars=tab:>-,trail:-

" Scroll window before point reaches the first or last line currently
" displayed.
set scrolloff=1

" Limit the number of characters displayed per line.
set wrap

" Disable scanning files for modelines which can be used to set per-file
" options.
set nomodeline

" Display opened folds with minus and closed folds with plus in a column
" of the given width at the left margin of the editor window.
"set foldcolumn=4

" Width of a tab character.
set tabstop=4

" Backspace and <C-h> remove this number spaces at once when these spaces
" occur at the beginning of a line, i.e. when they are used for indentation.
" Deleting backwards spaces which occur after non-white characters still only
" removes on space at a time.
set softtabstop=2

" Amount of indentation added or removed via >> and << in normal mode.
" This should probably be equal to the value for tabstop.
set shiftwidth=2

" Insert spaces when pressing <Tab> in insert mode.
set expandtab

" Always display tab page labels, even if there is only one tab.
set showtabline=2

" Set the mapleader.
let mapleader=" "

" Disable expandtab in Makefiles where recipes must be indented using actual
" tabs instead of a sequence of spaces.
autocmd FileType make setlocal ts=4 sts=4 sw=4 noexpandtab

" Use clang-format instead of Vim's built-in formatter for C/C++ files.
autocmd FileType c,cpp setlocal formatprg=clang-format

" Bash-like autocompletion in command mode.
set wildmode=longest,list

" Disable spell-checking by default. Set the language to en_gb meaning British
" English. The default would be en which accepts all regional English
" variations including Great Britain, United States and some more.
set nospell
set spelllang=en_gb

" Insert include guard for C/C++ header files.
" Author as a script local variable specified via "s:".
let s:author = "Michael Wende"
function! HeaderDoc()
  execute "normal i/*! \\file"
  execute "normal o \\brief"
  execute "normal o\\author " . s:author
  execute "normal o/"
endfunction

function! s:HeaderGuard()
  " Transform file name to upper case and replace occurrences of "." with "_".
  " Modified file name %:t retains only the tail of %, i.e. leading path
  " compontents are removed.
  let s:fildef = tr(toupper(expand("%:t")), ".", "_")
  execute "normal o#ifndef " . s:fildef
  execute "normal o#define " . s:fildef
  execute "normal 2o"
  execute "normal o#endif"
endfunction

function! Header()
  " Delete entire file contents.
  %d
  " Generate documentation block.
  call HeaderDoc()
  " Separate documentation block and include guard by an empty line.
  execute "normal o"
  " Generate preprocessor include guard macro.
  call <SID>HeaderGuard()
  " Move to the end of the line containing the brief file description tag.
  execute "normal 8k$"
endfunction
" Map command to function.
command! -nargs=0 Header call Header()

" Surround the given range with a C linkage block if the __cplusplus macro is
" definined. This can be useful not only in C but also in C++ code.
" In the function the necessary lines for closing the block are inserted
" first since the addition of new lines to the file changes the line
" numbering.
function! s:CLinkage() range
  " Close extern C block.
  execute a:lastline
  execute "normal o\n#ifdef __cplusplus"
  execute "normal o}"
  execute "normal o#endif"
  " Open extern C block.
  execute a:firstline
  execute "normal O#ifdef __cplusplus"
  execute "normal oextern \"C\" {"
  execute "normal o#endif\n"
endfunction

command! -nargs=0 -range CLinkage <line1>,<line2>call <sid>CLinkage()

" Frame single line of a C comment.
function! Frame()
  execute "normal yyplv$hhr*kPlv$hhr*"
endfunction
" Map command to function.
command! -nargs=0 Frame call Frame()

" Clean up whitespace.
function! s:Clean()
  " Replace tabs with spaces.
  execute "retab"
  " Remove trailing whitespace.
  try
    execute "%s/\\s\\+$//"
  catch
    echo "No trailing whitespace found."
  endtry
endfunction
command! -nargs=0 Clean call <sid>Clean()

" Run pdflatex on the current buffer.
" The shorter function name Tex is already used by the NetRW plugin.
function! Latex()
  execute "w|!pdflatex %"
endfunction
" Map command to function.
command! -nargs=0 Latex call Latex()

" Edit a new file and add it to a mercurial repository.
function! Hgedit(file_name)
  execute "edit " . a:file_name
  write
  execute "! hg -v add " . a:file_name
endfunction
command! -nargs=1 -complete=file Hgedit call Hgedit(<f-args>)

" Prepare a C/C++ include statement of the form
"   #include "" or #include <>
" placing the cursor betwen "" or <> and go to insert mode.
" Function for deciding where the include statement is inserted.
" If the current line is all white, replace the current line.
" Otherwise open a new line where the include statement will be placed.
" Prefix s: declares a script-local function.
function! s:IncludeNewLine()
  " If the current line is empty or consists of white space only.
  " Note that patterns have to appear on the right hand side of =~.
  " Regex characters in the left hand side are not recognized.
  " Backslash appearing in the white space character \s has to be doubled
  " within a double quoted string.
  " Alternatively a single quoted string could have been used.
  if getline(".") =~ "^\\s*$"
    " Remove all white space on the current line.
    execute "normal cc"
  else
    " Open a new line below the current.
    execute "normal o"
  endif
endfunction
" Prefix <SID> restrict function look up to script local functions.
nmap <leader>i :call <SID>IncludeNewLine()<CR>i#include "<Esc>i"
nmap <leader>I :call <SID>IncludeNewLine()<CR>i#include ><Esc>i<

" Scroll slower than up and down would usually do, only ten lines at a time.
nnoremap <C-U> 10<C-Y>
nnoremap <C-D> 10<C-E>

" Make it easier to open files from the same directory as the file which is
" currently being edited according to the suggestions from
"   vimcasts.org/e/14
nnoremap <leader>ew :edit    <C-r>=expand("%:p:h") . "/" <CR>
nnoremap <leader>es :split   <C-r>=expand("%:p:h") . "/" <CR>
nnoremap <leader>ev :vsplit  <C-r>=expand("%:p:h") . "/" <CR>
nnoremap <leader>et :tabedit <C-r>=expand("%:p:h") . "/" <CR>

" Open and focus Nerd Tree.
nnoremap <leader>t :NERDTree<CR>
nnoremap <leader>f :NERDTreeFocus<CR>
nnoremap <leader>F :NERDTreeFind<CR>
nnoremap <leader>c :NERDTreeClose<CR>

" Show buffer list of the bufexplorer plugin.
let g:bufExplorerFindActive = 1
let g:bufExplorerDisableDefaultKeyMapping = 1
noremap <unique> <leader>b :BufExplorer<CR>

" Commands for switching from editing a C/ C++ source file to editing the
" corresponding header file or vice versa. Source and header files are
" assumed to be located in the same directory and share the same names except
" for the suffix. Source files are assumed to end in .c or .cpp and header
" files are assumed to end in .h or .hpp.

" Convert source or forward declaration header file name to source file name.
function! s:SourceOrFwdHeaderToHeader()
  " Substitution with this pattern also converts a file name of
  " .*_fwd.cpp to .*.hpp which should not constitute a problem.
  return substitute(expand('%'), '\(_fwd\)\?\.[ch]\(pp\)\?$', '.h\2', '')
endfunction

" Convert (forward) header file name to source file name.
function! s:HeaderOrFwdHeaderToSource()
  return substitute(expand('%'), '\(_fwd\)\?\.h\(pp\)\?$', '.c\2', '')
endfunction

" Convert header file name to forward declaration header name.
function! s:HeaderOrSourceToFwdHeader()
  return substitute(expand('%'), '\.[ch]\(pp\)\?', '_fwd.h\1', '')
endfunction

" Switch to C/C++ header file.
map <leader>eh :edit <C-r>=<SID>SourceOrFwdHeaderToHeader() <CR> <CR>
" Switch to C/C++ source file.
map <leader>ec :edit <C-r>=<SID>HeaderOrFwdHeaderToSource() <CR> <CR>
" Switch to C/C++ forward declartion header file.
map <leader>ef :edit <C-r>=<SID>HeaderOrSourceToFwdHeader() <CR> <CR>

" Switch to alternate buffer.
nmap <leader>a :b#<cr>

" Shortcuts for switching between buffers.
" Up and down arrow keys for writing and cycling between buffers.
nmap <up> :bp<cr>
nmap <down> :bn<cr>
" The same for tabs using left and right arrow keys.
nmap <left> :tabprev<cr>
nmap <right> :tabnext<cr>

" Move through quick fix list items as in Tim Pope's Vim Unimpaired plugin.
nmap ]q :cnext<cr>
nmap [q :cprevious<cr>
" Same for the the location list.
nmap ]l :lnext<cr>
nmap [l :lprevious<cr>

" In normal mode insert a new line before or after the current
" line without entering insert mode.
" Multiple lines may be inserted by giving a count.
function! InsertLine(line_off, count)
  let l:line = line(".") + a:line_off
  let l:count = a:count
  while l:count
    call append(l:line, "")
    let l:count = l:count - 1
  endwhile
endfunction
nmap <leader>O :<C-U>call InsertLine(-1, v:count1) <cr>
nmap <leader>o :<C-U>call InsertLine( 0, v:count1) <cr>

" Use Y to yank to the end of the line instead of yanking the entire line.
" With this mapping Y and yy are related in the same way as D and dd.
map Y y$

" Remove comment leader when formatting comment lines by specifying the j flag.
" Recognise numbered lists when formatting text by specifying the n flag.
set formatoptions+=jn

" Netrw tree style listing.
let g:netrw_liststyle= 4

" Autocommand for sending the contents of a gnuplot script whose file name
" matches the pattern *.gpl to gnuplot when saving the current buffer to disk.
" Note that we need to avoid registering the autocommand more than once in
" when this code is sourced multiple times by remembering our registration of
" the autocommand by setting a global flag. Registering an autocommand more
" than once would result in multiple executions of that command each time the
" event occurs.
if !exists("g:autocommand_vimrc") || g:autocommand_vimrc  == 0
  let g:autocommand_vimrc = 1
  autocmd BufWritePost *.gpl call system("gnuplot -p < " . expand("%"))
endif

" ALE syntax checker.
" Disable higlight colors for errors and warnings.
let g:ale_set_highlights = 0
" Do not lint when opening a file or changing text,
" only lint when a file is being saved.
let g:ale_lint_on_enter = 0
let g:ale_lint_on_text_changed = 0

" Specify linters for C++ and JavaScript.
let g:ale_linters = {'cpp' : ['clang'], 'js' : ['eslint']}
let g:ale_sign_column_always = 1

" Clear the location list from linter messages.
" nmap <silent> <C-c> :ALEReset<Enter>
" nmap <silent> <C-l> :ALELint<Enter>
" Move forward and backward between errors.
" nmap <silent> <C-k> :ALEPrevious<Enter>
" nmap <silent> <C-j> :ALENext<Enter>

" Set theme for the airline plugin.
let g:airline_theme='term'

nmap <leader>z :FZF<cr>
set rtp+=~/local/fzf

" Save files and call make.
nnoremap <leader>m :wa\|!make<cr>

" Popup menu which can be used to perform a web search for the
" current word under the cursor position.
" The handler function receives the window id of the popup and the result
" index into the list of options. If the popup menu is cancelled the result
" index is -1.
function SearchPopupHandleResult(id, result)
  let l:i0 =  searchpos('\<', 'nb')[1] - 1
  let l:i1 =  searchpos('\>', 'n')[1] - 2
  let l:word = getline('.')[l:i0 : l:i1]
  if a:result == 1
    let l:domain = 'https://en.wikipedia.org/wiki/'
    let l:url = '"' . l:domain . l:word . '"'
    call system('snap run firefox ' . l:url)
  elseif a:result == 2
    let l:domain = 'https://duckduckgo.com/'
    let l:url = '"' . l:domain . '?sites=cppreference.com&q=' . l:word . '"'
    call system('snap run firefox ' . l:url)
  endif
endfunction
function SearchPopupOpen()
  let l:id = popup_menu(['Wikipedia', 'Cppreference'],
                      \ #{callback: 'SearchPopupHandleResult'})
endfunction
nnoremap <leader>s :call SearchPopupOpen()<cr>


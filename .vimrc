if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'christoomey/vim-tmux-navigator'
Plug 'crusoexia/vim-monokai'
Plug 'editorconfig/editorconfig-vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'leafgarland/typescript-vim'
Plug 'morhetz/gruvbox'
Plug 'pangloss/vim-javascript'
Plug 'peitalin/vim-jsx-typescript'
Plug 'scrooloose/nerdtree'
Plug 'thoughtbot/vim-rspec'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-surround'
Plug 'vim-ruby/vim-ruby'
Plug 'wincent/terminus'
call plug#end()

nnoremap <C-p> :call fzf#vim#tags(expand('<cword>'), {'options': '--exact --select-1'})<CR>
nnoremap d "_d
vnoremap p "_dP

vmap <C-c> "zy<Esc>:call system('pbcopy', @z)<CR>

set termguicolors
set laststatus=2
set ignorecase
set smartcase
syntax on
colorscheme monokai 
map <F2> :NERDTreeToggle<CR>
map <F3> :Files<CR>
map <F4> :NERDTree %<CR>
set tabstop=4 softtabstop=0 expandtab shiftwidth=2 smarttab number mouse=a clipboard=unnamed
set directory^=$HOME/.vim/tmp//

map <F5> :call RunCurrentSpecFile()<CR>
map <F6> :call RunNearestSpec()<CR>
map <F7> :call RunLastSpec()<CR>

let g:rspec_command = "Dispatch rspec {spec}"

let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let g:EditorConfig_exclude_patterns = ['fugitive://.\*', 'scp://.\*']

au BufNewFile,BufRead *.ejs set filetype=ejs

command! Kill call delete(expand('%')) | bdelete!
" --column: Show column number
" --line-number: Show line number
" --no-heading: Do not show file headings in results
" --fixed-strings: Search term as a literal string
" --ignore-case: Case insensitive search
" --no-ignore: Do not respect .gitignore, etc...
" --hidden: Search hidden files and folders
" --follow: Follow symlinks
" --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
" --color: Search color options
command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case  --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)
command! -bang -nargs=* CSFind call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>).'| tr -d "\017"', 1, <bang>0)

function! FindAndReplace( ... )
  if a:0 != 2
    echo "Need two arguments"
    return
  endif
  execute printf('args `rg --files-with-matches ''%s'' .`', a:1)
  execute printf('argdo %%substitute/%s/%s/g | update', a:1, a:2)
endfunction
command! -nargs=+ Jangle call FindAndReplace(<f-args>)

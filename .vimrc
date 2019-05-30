if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'vim-ruby/vim-ruby'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-commentary'
Plug 'thoughtbot/vim-rspec'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree'
Plug 'wincent/terminus'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
call plug#end()

nnoremap <C-p> :call fzf#vim#tags(expand('<cword>'), {'options': '--exact --select-1'})<CR>
nnoremap d "_d
vnoremap p "_dP

vmap <C-c> "zy<Esc>:call system('pbcopy', @z)<CR>

colorscheme wombat
map <F2> :NERDTreeToggle<CR>
map <F3> :Files<CR>
map <F4> :NERDTree %<CR>
command! Kill call delete(expand('%')) | bdelete!
set tabstop=4 softtabstop=0 expandtab shiftwidth=2 smarttab number mouse=a clipboard=unnamed

map <F5> :call RunCurrentSpecFile()<CR>
map <F6> :call RunNearestSpec()<CR>
map <F7> :call RunLastSpec()<CR>

let g:rspec_command = "Dispatch rspec {spec}"
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

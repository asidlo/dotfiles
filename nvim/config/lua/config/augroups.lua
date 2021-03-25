local autocmds = {
  nvim_settings = {
    {[[TextYankPost * silent! lua require'vim.highlight'.on_yank()]]},
    {[[TermOpen,TermEnter term://* startinsert!]]},
    {[[TermEnter term://* setlocal nonumber norelativenumber signcolumn=no]]}
  },
  filetype_settings = {
    {[[FileType vim setlocal tabstop=2 shiftwidth=2 foldmethod=marker foldenable]]},
    {[[FileType lua setlocal tabstop=2 shiftwidth=2]]},
    {[[FileType xml setlocal foldmethod=indent foldlevelstart=999 foldminlines=0]]},
    {[[FileType markdown,text setlocal textwidth=79 tabstop=2 shiftwidth=2]]},
    {[[FileType zsh setlocal foldmethod=marker tabstop=4 shiftwidth=4]]},
    {[[BufEnter *.jsh setlocal filetype=java]]},
    {[[FileType java,groovy setlocal foldlevel=2 tabstop=4 shiftwidth=4 expandtab colorcolumn=120]]},
    {[[BufEnter *.java compiler javac]]},
    {[[FileType c,cpp setlocal tabstop=4 shiftwidth=4 makeprg=clang++\ -Wall\ -std=c++17 commentstring=\/\/\ %s]]},
    {[[FileType c,cpp setlocal formatprg=clang-format]]},
    {[[BufEnter gitconfig setlocal filetype=gitconfig]]}
  },
  file_history = {
    {[[BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]}
  },
  dracula_customization = {
    {[[ColorScheme dracula highlight SpellBad gui=undercurl]]},
    {[[ColorScheme dracula highlight Search guibg=NONE guifg=Yellow gui=underline term=underline cterm=underline]]}
  },
  lsp_settings = {
    {[[BufAdd jdt://* call luaeval("require('lsp.jdtls').open_jdt_link(_A)", expand('<amatch>'))]]},
    {[[CursorMoved,InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs
      \ :lua require'lsp_extensions'.inlay_hints{ prefix = '', highlight = 'Comment', enabled = {'TypeHint', 'ChainingHint', 'ParameterHint'} }]]}
  },
}

nvim_create_augroups(autocmds)

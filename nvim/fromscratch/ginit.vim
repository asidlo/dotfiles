" Set font without error
GuiFont! MesloLGM\ NF:h11

" Remove tabline
GuiTabline 0

" Open in full windows mode
" call GuiWindowMaximized(1)

" Disable gross popup menu
GuiPopupmenu 0

" <Shift-Ins> just like gvim
inoremap <silent>  <S-Insert>  <C-R>+
cnoremap <S-Insert> <C-R>+

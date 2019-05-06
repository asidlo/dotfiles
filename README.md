# Dotfiles

## Issues

vim-go running :GoDoc -> `fatal error: 'stdlib.h' file not found`

```bash
open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg
```

vim-go running :GoRename -> `gorename: couldn't load packages due to errors`

- Link to [solution](https://github.com/redefiance/atom-go-rename/issues/5)

...basically redownload gorename binary w/ 

```bash
go get golang.org/x/tools/cmd/gorename
```

Same workaround for fixing the guru issues

```bash
go get golang.org/x/tools/cmd/guru
```

## TODO:

Plugins

- comments (nerd/commentary)
- syntax highlighting for other langs
- YouCompleteMe (autocompletion)
- cope? for ctrlp / bufexplorer
- yankstack
- gundo
- cscope (find all usages, for non go files)
- linting? (for non go files)
- surround
- autopairs
- multiple-cursors
- goyo/zenroom
- lightline vs powerline?
- vimdevicons for tricked out statusbar/plugins

Misc

- Remove unused vimrc settings
- Add Note/Tips section
- Tidy up zshrc, make single alias section
- Add check for .vim/ and undodir in init.sh


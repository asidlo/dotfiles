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

- YouCompleteMe (autocompletion)
- yankstack
- gundo
- goyo/zenroom

- syntax highlighting for other langs
- cscope (find all usages, for non go files)
- linting? (for non go files)
- surround
- autopairs
- multiple-cursors
- lightline vs powerline?

Misc

- Remove unused vimrc settings
- Add Note/Tips section
- Add check for .vim/ and undodir in init.sh


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
- Search plugin (fzf)...cope? / bufexplorer
- yankstack
- gundo
- cscope (find all usages)
- linting?
- surround
- autopairs
- multiple-cursors
- goyo/zenroom

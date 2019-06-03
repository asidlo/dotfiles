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

- yankstack
- gundo
- goyo/zenroom

- cscope (find all usages, for non go files)
- surround
- autopairs
- multiple-cursors
- lightline vs powerline?

Misc

- Remove unused vimrc settings
- Add Note/Tips section
- Add check for .vim/ and undodir in init.sh
- Have dotfiles init.sh also install brew packages/choco
- Visual line shifting does not include comments
- Remove stuff from vimrc dealing with languages besides go/rust?
- Include instructions for running :GoInstallBinaries on first vim load
- Include instructions for installing YouCompleteMe for go/rust
- Include .z files for prezto / install prezto

Install sdkman

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java
sdk install gradle
sdk install maven
sdk install kotlin
sdk install kscript
sdk install springboot
```

- https://sdkman.io/usage


Show Hidden Files in Finder: `CMD + SHIFT + .`

- https://ianlunn.co.uk/articles/quickly-showhide-hidden-files-mac-os-x-mavericks/

Npm Install Packages:

```
$ npm list -g --depth=0
/usr/local/lib
├── @vue/cli@3.8.2
├── bash-language-server@1.5.5
├── electron@4.0.6
├── npm@6.7.0
└── prettier@1.17.0
```


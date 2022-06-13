#!/bin/bash

set -e

mkdir -p ~/.local/bin

curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage -o ~/.local/nvim.appimage

chmod +x ~/.local/nvim.appimage

pushd ~/.local

./nvim.appimage --appimage-extract 

if [ -d ~/.local/nvim ]; then
    rm -rf ~/.local/nvim
fi
mv -f ./squashfs-root ~/.local/nvim

ln -svf ~/.local/nvim/AppRun ~/.local/bin/nvim

rm ./nvim.appimage

popd

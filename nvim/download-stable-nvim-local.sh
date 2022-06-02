#!/bin/bash

set -e

mkdir -p ~/.local/bin

curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o ~/.local/nvim.appimage

chmod +x ~/.local/nvim.appimage

pushd ~/.local

./nvim.appimage --appimage-extract 

mv -f ./squashfs-root ~/.local/nvim

ln -svf ~/.local/nvim/AppRun ~/.local/bin/nvim

rm ./nvim.appimage

popd

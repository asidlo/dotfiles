#!/bin/bash

# Script directory
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")

"$SCRIPT_DIR/rust.sh" && cargo install stylua

source /etc/os-release
case "$ID" in
debian | ubuntu)
	sudo apt-get install build-essential libreadline-dev unzip -y
	;;
esac

curl -R http://www.lua.org/ftp/lua-"$LUA_VERSION".tar.gz -o /tmp/lua.tar.gz
cd /tmp || exit 1
tar -zxf lua.tar.gz
rm /tmp/lua.tar.gz
cd /tmp/lua-"$LUA_VERSION" || exit 1
make linux test
sudo make install
cd ..
rm -rf ./lua-"$LUA_VERSION"

wget https://luarocks.org/releases/luarocks-"$LUAROCKS_VERSION".tar.gz
tar zxpf luarocks-"$LUAROCKS_VERSION".tar.gz
rm luarocks-"$LUAROCKS_VERSION".tar.gz
cd luarocks-"$LUAROCKS_VERSION" || exit 1
./configure --with-lua-include=/usr/local/include
make
sudo make install
cd ..
rm -rf luarocks-"$LUAROCKS_VERSION"

sudo luarocks install luacheck
sudo luarocks install lanes

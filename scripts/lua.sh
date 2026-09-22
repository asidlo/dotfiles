#!/bin/bash

# stylua ships prebuilt binaries, so never build it from source: `cargo install`
# needs a working rustc, which segfaults on start-up in emulated environments
# (its bundled jemalloc assumes userspace pointers are 48-bit clean, and faults
# on its first allocation when they are not).
install_stylua_from_release() {
  local arch tmp
  arch=$(uname -m)
  case "$arch" in
  x86_64 | aarch64) ;;
  *)
    echo "No prebuilt stylua binary for architecture '$arch'." >&2
    return 1
    ;;
  esac
  mkdir -p ~/.local/bin
  tmp=$(mktemp -d)
  curl -fsSL "https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux-${arch}-musl.zip" -o "$tmp/stylua.zip" || { rm -rf "$tmp"; return 1; }
  unzip -q -o "$tmp/stylua.zip" -d "$tmp" || { rm -rf "$tmp"; return 1; }
  install -m 0755 "$tmp/stylua" ~/.local/bin/stylua || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
}

install_stylua_from_release

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

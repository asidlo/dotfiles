#!/bin/bash

set -e -o pipefail

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

# echo an error message before exiting
trap '[ $? -ne 0 ] && echo "\"${last_command}\" command failed with exit code $?."' EXIT

# * Check if running in WSL and make sure to symlink /etc/wsl.conf since we dont want to
#   include windows paths when using npm
# * Also symlink from C:\Program Files\Neovim\bin\win32yank.exe to ~/.local/bin/win32yank.exe
# * Also would be good to maybe have it install the lsps and the treesitter syntaxs when installing nvim
# * And should refactor into functions that can be called via flags
# * Figure out how to install latest instead of fixed versions

DOTFILES_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")

echo "Installing using the following configuration:"

[ "$RG_VERSION" != "" ] || RG_VERSION="$(curl -s -I https://github.com/BurntSushi/ripgrep/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')"
[ "$FD_VERSION" != "" ] || FD_VERSION="$(curl -s -I https://github.com/sharkdp/fd/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
[ "$DOTNET_VERSION" != "" ] || DOTNET_VERSION="8.0"
[ "$UBUNTU_VERSION" != "" ] || UBUNTU_VERSION="$(cat /etc/os-release | grep "VERSION_ID" | cut -d"=" -f2 | sed 's/"//g')"
[ "$BAT_VERSION" != "" ] || BAT_VERSION="$(curl -s -I https://github.com/sharkdp/bat/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
[ "$NERDFONT_VERSION" != "" ] || NERDFONT_VERSION="$(curl -s -I https://github.com/ryanoasis/nerd-fonts/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
[ "$GO_VERSION" != "" ] || GO_VERSION="1.19.4"
[ "$GITCONFIG" != "" ] || GITCONFIG="gitconfig"
[ "$LUA_VERSION" != "" ] || LUA_VERSION="5.4.4"
[ "$LUAROCKS_VERSION" != "" ] || LUAROCKS_VERSION="3.9.1"
[ "$JAVA_VERSION" != "" ] || JAVA_VERSION="17.0.3-ms"
[ "$NETCOREDBG_VERSION" != "" ] || NETCOREDBG_VERSION="2.2.0-947"

if [ "$INSTALL_ALL" != "" ] && [ "$INSTALL_ALL" -eq 1 ]; then
	INSTALL_MARKDOWN=1
	INSTALL_JAVA=1
	INSTALL_LUA=1
	INSTALL_BASH=1
	INSTALL_PYTHON=1
	INSTALL_DOTNET=1
	INSTALL_NODE=1
	INSTALL_NVIM=1
fi

if [ "$INSTALL_NVIM" -eq 1 ]; then
	INSTALL_NODE=1
	INSTALL_PYTHON=1
fi

echo "Installing using the following configuration:"
echo "- RG_VERSION=$RG_VERSION"
echo "- FD_VERSION=$FG_VERSION"
echo "- DOTNET_VERSION=$DOTNET_VERSION"
echo "- UBUNTU_VERSION=$UBUNTU_VERSION"
echo "- BAT_VERSION=$BAT_VERSION"
echo "- GO_VERSION=$GO_VERSION"
echo "- GITCONFIG=$GITCONFIG"
echo "- LUA_VERSION=$LUA_VERSION"
echo "- LUAROCKS_VERSION=$LUAROCKS_VERSION"
echo "- JAVA_VERSION=$JAVA_VERSION"
echo "- NETCOREDBG_VERSION=$NETCOREDBG_VERSION"
echo "- NERDFONT_VERSION=$NERDFONT_VERSION"
echo "- INSTALL_MARKDOWN=$INSTALL_MARKDOWN"
echo "- INSTALL_JAVA=$INSTALL_JAVA"
echo "- INSTALL_LUA=$INSTALL_LUA"
echo "- INSTALL_BASH=$INSTALL_BASH"
echo "- INSTALL_PYTHON=$INSTALL_PYTHON"
echo "- INSTALL_DOTNET=$INSTALL_DOTNET"
echo "- INSTALL_NODE=$INSTALL_NODE"
echo "- INSTALL_NVIM=$INSTALL_NVIM"

USER=$(whoami)
OS=$(cat /etc/os-release | grep "^ID=*" | cut -d"=" -f2)
is_root() {
	[ "$USER" != "" ] && [ "$USER" == "root" ]
}

install_npm() {
	command -v npm >/dev/null && return 0

	# Install nvm for npm and nodejs
	curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

	# Removes decimal to use built in integer math instead of floats
	if (($(echo "$UBUNTU_VERSION" | sed 's/\.//g') > 1804)); then
		nvm install --lts
	else
		nvm install 16.15.1
	fi
}

install_cargo() {
	command -v cargo >/dev/null 2>&1 && return 0

	# Install cargo for rust dev
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	source "$HOME"/.cargo/env
}

export DEBIAN_FRONTEND=noninteractive

if is_root; then
	export HOME=/root

	# Had issues in container with following error: dpkg: error: PATH is not set
	export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	apt-get update -y && apt-get install sudo -y
fi

if [ "$OS" == "mariner" ]; then
	sudo dnf update -y
else
	sudo apt-get update -y
fi

# Download dotfiles and link if file is not already present and a symlink
ln -sfv "$DOTFILES_DIR/git/$GITCONFIG" ~/.gitconfig
ln -sfv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv
ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
ln -sfv "$DOTFILES_DIR/vim/minimal.vim" ~/.vimrc
ln -sfv "$DOTFILES_DIR/misc/hushlogin" ~/.hushlogin
ln -sfv "$DOTFILES_DIR/misc/shellcheckrc" ~/.shellcheckrc

mkdir -p ~/.docker
ln -sfv "$DOTFILES_DIR/misc/docker.config.json" ~/.docker/config.json

mkdir -p ~/.omnisharp
ln -sfv "$DOTFILES_DIR/misc/omnisharp.json" ~/.omnisharp/omnisharp.json

mkdir -p ~/.config
ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml

mkdir -p ~/.local/bin
curl -sfL git.io/antibody | sh -s - -b ~/.local/bin

# Install ripgrep
# https://github.com/BurntSushi/ripgrep
# Latest version of rg deb (>14.0.0) includes a -1 at the end of the version for some reason.
curl -L https://github.com/BurntSushi/ripgrep/releases/download/"$RG_VERSION"/ripgrep_"$RG_VERSION"-1_amd64.deb -o /tmp/ripgrep.deb
sudo apt-get install /tmp/ripgrep.deb
rm /tmp/ripgrep.deb

# Install fd
# https://github.com/sharkdp/fd
curl -L https://github.com/sharkdp/fd/releases/download/v"$FD_VERSION"/fd_"$FD_VERSION"_amd64.deb -o /tmp/fd.deb
sudo apt-get install /tmp/fd.deb
rm /tmp/fd.deb

# Install bat
curl -L https://github.com/sharkdp/bat/releases/download/v"$BAT_VERSION"/bat_"$BAT_VERSION"_amd64.deb -o /tmp/bat.deb
sudo apt-get install /tmp/bat.deb
rm /tmp/bat.deb

# Install nerd-fonts
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v"$NERDFONT_VERSION"/Meslo.zip -o /tmp/Meslo.zip
sudo apt-get install -y unzip
sudo unzip /tmp/Meslo.zip -d /usr/share/fonts/truetype/meslo
sudo apt-get install -y fontconfig
sudo fc-cache -vf /usr/share/fonts/
rm /tmp/Meslo.zip

# Install starship
curl -sS https://starship.rs/install.sh | sudo sh -s -- -y

# Install zsh
# codespaces adds a zlogin by default
if ! type zsh >/dev/null 2>&1; then
	if [ -f /etc/zsh/zlogin ]; then
		sudo mv /etc/zsh/zlogin /etc/zsh/zlogin.bkp
	fi
	sudo apt-get install zsh -y
	if [ -f /etc/zsh/zlogin.bkp ]; then
		sudo mv /etc/zsh/zlogin.bkp /etc/zsh/zlogin
	fi
fi

# Set zsh as current shell
sudo chsh -s /bin/zsh "$USER"

# Install fzf
mkdir -p ~/.local/src
if [ ! -d ~/.local/src/fzf/ ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.local/src/fzf
fi
~/.local/src/fzf/install --xdg --key-bindings --completion --no-update-rc --no-bash --no-fish
ln -svf ~/.local/src/fzf/bin/fzf ~/.local/bin/fzf

# For generating english locales to be set via zshrc and used for character rendering
# sudo apt-get update -y && sudo apt-get install language-pack-en -y

sudo apt-get install locales -y

# Ensure at least the en_US.UTF-8 UTF-8 locale is available.
# Common need for both applications and things like the agnoster ZSH theme.
if ! grep -o -E '^\s*en_US.UTF-8\s+UTF-8' /etc/locale.gen >/dev/null; then
	sudo bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen'
	sudo locale-gen
fi

# Install powershell
sudo apt-get update &&
	sudo apt-get install -y wget apt-transport-https software-properties-common &&
	wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" &&
	sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && sudo apt-get update &&
	sudo apt-get install -y powershell

curl -L https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 -o /tmp/bicep
chmod +x /tmp/bicep
mv /tmp/bicep ~/.local/bin/bicep

if [ ! -d ~/.tmux/plugins/tpm ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
mkdir /tmp/lazygit && tar xf /tmp/lazygit.tar.gz -C /tmp/lazygit
mv /tmp/lazygit/lazygit ~/.local/bin && rm -rf /tmp/lazygit && rm /tmp/lazygit.tar.gz

if [ "$INSTALL_NVIM" != "" ] && [ "$INSTALL_NVIM" -eq 1 ]; then
	# Install nvim runtime prerequisites
	sudo apt-get install build-essential tmux wget curl zip unzip -y

	# Install nvim
	if (($(echo "$UBUNTU_VERSION" | sed 's/\.//g') > 1804)); then
		# https://gist.github.com/gvenzl/1386755861fb42db492276d3864a378c
		latest_tag=$(curl -s https://api.github.com/repos/MordechaiHadad/bob/releases/latest | sed -Ene '/^ *"tag_name": *"(v.+)",$/s//\1/p')
		echo "Using version $latest_tag"

		curl -L -o /tmp/bob.zip "https://github.com/MordechaiHadad/bob/releases/download/$latest_tag/bob-linux-x86_64.zip"
		unzip /tmp/bob.zip -d /tmp/bob
		chmod +x /tmp/bob/bob-linux-x86_64/bob
		mv /tmp/bob/bob-linux-x86_64/bob ~/.local/bin
		rm -f /tmp/bob.zip && rm -rf /tmp/bob

		# Install nightly neovim
		mkdir -p ~/.local/share
		~/.local/bin/bob use stable

		# Add current neovim version to PATH
		ln -svf ~/.local/share/bob/nvim-bin/nvim ~/.local/bin/nvim
	else
		~/.local/src/dotfiles/nvim/download-stable-nvim-local.sh
	fi

	# Add symlink for config
	[ -L ~/.config/nvim ] || ln -sv "$DOTFILES_DIR/nvim/lazynvim" ~/.config/nvim
fi

if [ "$INSTALL_NODE" != "" ] && [ "$INSTALL_NODE" -eq 1 ]; then
	install_npm
fi

# Install dotnet
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#register-the-microsoft-package-repository
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-package-mixup?pivots=os-linux-ubuntu#i-need-a-version-of-net-that-isnt-provided-by-my-linux-distribution
if [ "$INSTALL_DOTNET" != "" ] && [ "$INSTALL_DOTNET" -eq 1 ]; then
	wget https://packages.microsoft.com/config/ubuntu/"$UBUNTU_VERSION"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
	sudo dpkg -i packages-microsoft-prod.deb
	rm packages-microsoft-prod.deb
	sudo apt-get update
	sudo apt-get install -y apt-transport-https &&
		sudo apt-get update &&
		sudo apt-get install -y dotnet-sdk-"$DOTNET_VERSION"

	# dotnet debugger deps for netcoredbg
	# https://stackoverflow.com/a/66465559
	#     sudo apt-get update
	#     sudo apt-get install -y wget gcc-8 unzip libssl1.0.0 software-properties-common
	#     sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
	#     sudo apt-get update
	#     sudo apt-get install -y --only-upgrade libstdc++6

	curl -L https://github.com/Samsung/netcoredbg/releases/download/"$NETCOREDBG_VERSION"/netcoredbg-linux-amd64.tar.gz -o /tmp/netcoredbg-linux-amd64.tar.gz
	tar xzvf /tmp/netcoredbg-linux-amd64.tar.gz -C /tmp
	mv /tmp/netcoredbg/* ~/.local/bin
	rm /tmp/netcoredbg-linux-amd64.tar.gz && rm -rf /tmp/netcoredbg
fi

if [ "$INSTALL_PYTHON" != "" ] && [ "$INSTALL_PYTHON" -eq 1 ]; then
	sudo apt-get install python3-venv python3-pip -y
	/usr/bin/python3 -m pip install pynvim
	pip3 install black
fi

if [ "$INSTALL_GO" != "" ] && [ "$INSTALL_GO" -eq 1 ]; then
	curl -L https://go.dev/dl/go"$GO_VERSION".linux-amd64.tar.gz -o /tmp/go.tar.gz
	sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz
	rm /tmp/go.tar.gz
fi

# Install sdkman for java
if [ "$INSTALL_JAVA" != "" ] && [ "$INSTALL_JAVA" -eq 1 ]; then
	curl -s "https://get.sdkman.io" | bash
	source "$HOME/.sdkman/bin/sdkman-init.sh"
	sdk i java "$JAVA_VERSION"
fi

# Install formatters/linters
if [ "$INSTALL_LUA" != "" ] && [ "$INSTALL_LUA" -eq 1 ]; then
	install_cargo && cargo install stylua

	sudo apt-get install build-essential libreadline-dev unzip -y
	curl -R http://www.lua.org/ftp/lua-"$LUA_VERSION".tar.gz -o /tmp/lua.tar.gz
	cd /tmp
	tar -zxf lua.tar.gz
	rm /tmp/lua.tar.gz
	cd /tmp/lua-"$LUA_VERSION"
	make linux test
	sudo make install
	cd ..
	rm -rf ./lua-"$LUA_VERSION"

	wget https://luarocks.org/releases/luarocks-"$LUAROCKS_VERSION".tar.gz
	tar zxpf luarocks-"$LUAROCKS_VERSION".tar.gz
	rm luarocks-"$LUAROCKS_VERSION".tar.gz
	cd luarocks-"$LUAROCKS_VERSION"
	./configure --with-lua-include=/usr/local/include
	make
	sudo make install
	cd ..
	rm -rf luarocks-"$LUAROCKS_VERSION"

	sudo luarocks install luacheck
	sudo luarocks install lanes
fi

if [ "$INSTALL_BASH" != "" ] && [ "$INSTALL_BASH" -eq 1 ]; then
	install_cargo && cargo install shellharden
	sudo apt-get install shellcheck -y
fi

if [ "$INSTALL_MARKDOWN" != "" ] && [ "$INSTALL_MARKDOWN" -eq 1 ]; then
	install_npm
	npm install -g @fsouza/prettierd
	npm install -g markdownlint-cli
	ln -sfv "$DOTFILES_DIR/markdownlint.json" ~/.markdownlint.json
fi

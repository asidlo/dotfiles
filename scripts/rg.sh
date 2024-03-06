#!/bin/bash

# Install ripgrep
# https://github.com/BurntSushi/ripgrep
# Latest version of rg deb (>14.0.0) includes a -1 at the end of the version for some reason.
curl -L https://github.com/BurntSushi/ripgrep/releases/download/"$RG_VERSION"/ripgrep_"$RG_VERSION"-1_amd64.deb -o /tmp/ripgrep.deb
sudo apt-get install /tmp/ripgrep.deb
rm /tmp/ripgrep.deb

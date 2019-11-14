!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# The following variables are the defaults, modify as needed
# export NODE_VERSION=12 # supports any manjor version from https://github.com/nodesource/distributions 
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-nodejs.sh | bash
# -----------------------------

if [ ! -v NODE_VERSION ]; then NODE_VERSION=12; fi

sudo apt-get install curl -y

# install nodejs
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs

# install build tools
sudo apt-get install -y build-essential

# install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update -y
sudo apt install yarn -y

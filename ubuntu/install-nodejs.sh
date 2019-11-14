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

curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y build-essential

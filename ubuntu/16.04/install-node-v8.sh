#!/bin/sh

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
# curl $DOWNLOAD_URL_BASE/install-node-v8.sh | bash
# -----------------------------

# Install nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install node
nvm install v8.9.4
nvm alias default v8.9.4
nvm use default
npm i -g rimraf dotenv pm2 forever nodemon

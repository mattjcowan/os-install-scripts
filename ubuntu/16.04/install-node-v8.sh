#!/bin/sh

# Install nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash

# Install node
nvm install v8.9.1
nvm alias default v8.9.1
nvm use default
npm i -g rimraf dotenv pm2 forever nodemon

#!/bin/bash

# INSTRUCTIONS
# Call this script with:
#
# SCRIPT_BASE_URL=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
# SCRIPT_NAME=install-node-v10.sh
# mkdir -p /tmp
# curl -o /tmp/$SCRIPT_NAME $SCRIPT_BASE_URL$SCRIPT_NAME
# chmod +x /tmp/$SCRIPT_NAME
# sudo /tmp/$SCRIPT_NAME

curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo apt-get update
sudo apt-get install nodejs -y
npm install -g yarn
npm install -g npx
npm install -g np
npm install -g npm-name-cli
npm install -g tldr
npm install -g now
npm install -g gulp
npm install -g less
npm install -g node-sass
npm install -g rimraf
npm install -g dotenv
npm install -g pm2
npm install -g forever
npm install -g nodemon
npm install -g http-server

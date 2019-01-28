#!/bin/bash

curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo apt-get update
sudo apt-get install nodejs -y
sudo npm install -G rimraf pm2 forever nodemon http-server node-sass

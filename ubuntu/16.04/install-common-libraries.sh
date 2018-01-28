#!/bin/sh

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
# curl $DOWNLOAD_URL_BASE/install-common-libraries.sh | bash
# -----------------------------

sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install nano -y
sudo apt-get install git -y
sudo apt-get install sqlite3 -y
sudo apt-get install libsqlite3-dev -y

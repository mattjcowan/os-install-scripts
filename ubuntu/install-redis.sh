!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# If you do not export a password, one will be created for you and available inside /etc/redis/redis.conf
# -----------------------------
# export REDIS_PASSWORD=3m9nJP0XfaNqVd0Nwzfp19l31ejxVS5mvu4nUISh6448YKlUPO1glfli4iJHHWsmWugAEfOYx3cBixy
# export REDIS_REMOTE_CONNECTIONS=yes # options: yes (default), no
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-redis.sh | bash
# -----------------------------

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')

if [ "$OS_VERSION" == "16.04" ]; then
  wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04/install-redis.sh | bash
else
  wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/18.04/install-redis.sh | bash
fi

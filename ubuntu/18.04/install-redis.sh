!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# If you do not export a password, one will be created for you and available inside /etc/redis/redis.conf
# -----------------------------
# export REDIS_PASSWORD=3m9nJP0XfaNqVd0Nwzfp19l31ejxVS5mvu4nUISh6448YKlUPO1glfli4iJHHWsmWugAEfOYx3cBixy
# export REDIS_REMOTE_CONNECTIONS=yes # options: yes (default), no
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/18.04/install-redis.sh | bash
# -----------------------------

if [ ! -v REDIS_PASSWORD ]; then 
  REDIS_PASSWORD=$(openssl rand 60 | openssl base64 -A); 
  REDIS_PASSWORD=$(echo "${REDIS_PASSWORD}" | sed 's/[^a-zA-Z0-9]//g');
fi
if [ ! -v REDIS_REMOTE_CONNECTIONS ]; then REDIS_REMOTE_CONNECTIONS=yes; fi

# run updates
sudo apt-get update -y

# install redis
sudo apt-get install ufw redis-server -y

# set the redis password
sudo sed -i "s/#\srequirepass/requirepass/g" /etc/redis/redis.conf
sudo sed -i "s/^requirepass.*/requirepass $REDIS_PASSWORD/g" /etc/redis/redis.conf

# run redis as a service
sudo sed -i "s/^supervised.*/supervised systemd/g" /etc/redis/redis.conf
sudo sed -i "s/^dir.*/dir \/var\/lib\/redis/g" /etc/redis/redis.conf

# enable external connections (if told to do so)
if [ "$REDIS_REMOTE_CONNECTIONS" == "yes" ]; then
  sudo sed -i "s/#\sprotected-mode/protected-mode/g" /etc/redis/redis.conf
  sudo sed -i "s/^protected-mode.*/protected-mode no/g" /etc/redis/redis.conf
  sudo sed -i "s/^bind.*/bind 0.0.0.0/g" /etc/redis/redis.conf
fi

# start the redis service
sudo systemctl start redis.service
sudo systemctl restart redis.service

# open the firewall to allow external connections
if [ "$REDIS_REMOTE_CONNECTIONS" == "yes" ]; then
  sudo ufw allow OpenSSH
  sudo ufw allow 6379
  sudo ufw allow 6379/tcp
  sudo ufw reload
  sudo ufw --force enable
fi

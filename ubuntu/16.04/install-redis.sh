!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# If you do not export a password, one will be created for you and available inside /etc/redis/redis.conf
# -----------------------------
# export REDIS_PASSWORD=3m9nJP0XfaNqVd0Nwzfp19l31ejxVS5mvu4nUISh6448YKlUPO1glfli4iJHHWsmWugAEfOYx3cBixy
# export REDIS_REMOTE_CONNECTIONS=yes # options: yes (default), no
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04/install-redis.sh | bash
# -----------------------------

if [ ! -v REDIS_PASSWORD ]; then 
  sudo apt-get update -y
  sudo apt-get install openssl -y
  REDIS_PASSWORD=$(openssl rand 60 | openssl base64 -A); 
  REDIS_PASSWORD=$(echo "${REDIS_PASSWORD}" | sed 's/[^a-zA-Z0-9]//g');
fi
if [ ! -v REDIS_REMOTE_CONNECTIONS ]; then REDIS_REMOTE_CONNECTIONS=yes; fi

# add `ppa` that has the latest redis version on it, run updates, and install redis
# sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt-get update -y
sudo apt-get install build-essential tcl -y

# download and install the latest redis stable archive
cd /tmp
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable
make && sudo make install

# configure redis
sudo mkdir -p /etc/redis
if [ ! -f /etc/redis/redis.conf ]; then sudo cp /tmp/redis-stable/redis.conf /etc/redis; fi

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

# make sure the systemd service definition exists
if [ ! -f /etc/systemd/system/redis.service ]; then
cat >/tmp/redis.service <<EOL
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOL
sudo mv /tmp/redis.service /etc/systemd/system/redis.service
fi

# setup the redis user
sudo id -u redis &>/dev/null || sudo adduser --system --group --no-create-home redis
sudo mkdir -p /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis
  
# start the redis service
sudo systemctl stop redis
sudo systemctl start redis
sudo systemctl enable redis

# open the firewall to allow external connections
if [ "$REDIS_REMOTE_CONNECTIONS" == "yes" ]; then
  sudo ufw allow OpenSSH
  sudo ufw allow 6379
  sudo ufw allow 6379/tcp
  sudo ufw reload
  sudo ufw --force enable
fi

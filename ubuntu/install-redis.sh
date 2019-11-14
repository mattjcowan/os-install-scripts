!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# export REDIS_PASSWORD=3m9nJP0XfaNqVd0Nwzfp19l31ejxVS5mvu4nUISh6448YKlUPO1glfli4iJHHWsmWugAEfOYx3cBixy
# export REDIS_REMOTE_CONNECTIONS=yes # options: yes (default), no
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-redis.sh | bash
# -----------------------------

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')

if [ ! -v REDIS_PASSWORD ]; then 
  REDIS_PASSWORD=$(openssl rand 60 | openssl base64 -A); 
  REDIS_PASSWORD=$(echo "${REDIS_PASSWORD}" | sed 's/[^a-zA-Z0-9]//g');
fi
if [ ! -v REDIS_REMOTE_CONNECTIONS ]; then REDIS_REMOTE_CONNECTIONS=yes; fi

sudo apt-get update -y
sudo apt-get install ufw -y

if [ "$OS_VERSION" == "16.04" ]; then
  sudo apt-get install build-essential curl tcl -y
  cd /tmp
  curl -O http://download.redis.io/redis-stable.tar.gz
  tar xzvf redis-stable.tar.gz
  cd redis-stable
  make
  sudo make install
  sudo mkdir /etc/redis
  sudo cp /tmp/redis-stable/redis.conf /etc/redis
else
  sudo apt-get install redis-server -y
fi

# run redis as a service
if [ "$REDIS_PASSWORD" != "" ]; then
  sudo sed -i "s/#\srequirepass/requirepass/g" /etc/redis/redis.conf
  sudo sed -i "s/^requirepass.*/requirepass $REDIS_PASSWORD/g" /etc/redis/redis.conf
fi

sudo sed -i "s/^supervised.*/supervised systemd/g" /etc/redis/redis.conf
sudo sed -i "s/^dir.*/dir \/var\/lib\/redis/g" /etc/redis/redis.conf

if [ "$REDIS_REMOTE_CONNECTIONS == "yes" ]; then
  sudo sed -i "s/# protected-mode/protected-mode/g" /etc/redis/redis.conf
  sudo sed -i "s/^protected-mode.*/protected-mode no/g" /etc/redis/redis.conf
  sudo sed -i "s/^bind.*/bind 0.0.0.0/g" /etc/redis/redis.conf
fi

if [ "$OS_VERSION" == "16.04" ]; then
if [ ! -f /etc/systemd/system/redis.service ]; then
cat >/etc/systemd/system/redis.service <<EOL
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
fi

sudo adduser --system --group --no-create-home redis
sudo mkdir -p /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis
fi

if [ -f /lib/systemd/system/redis-server.service ]; then
if [ ! -f /etc/systemd/system/redis.service ]; then
  sudo ln -s /lib/systemd/system/redis-server.service /etc/systemd/system/redis.service
fi
fi

# start the redis service
sudo systemctl start redis.service
sudo systemctl restart redis.service
sudo systemctl enable redis

sudo ufw allow 6379
sudo ufw allow 6379/tcp
sudo ufw --force enable

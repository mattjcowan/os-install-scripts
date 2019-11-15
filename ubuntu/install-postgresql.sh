!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# The following variables are the defaults, modify as needed
# export PG_PASSWORD='YuiXQlk_d@WushaIDO@as^asSIOus'  # required
# export PG_ALLOW_REMOTE_CONNECTIONS=yes # options: no, yes (default)
# export PG_VERSION=11  # possible options: 9.6, 10, 11, 12
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-postgresql.sh | bash
# -----------------------------

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
OS_CODENAME=$(grep -oP '(?<=^UBUNTU_CODENAME=).+' /etc/os-release | tr -d '"')

if [ ! -v PG_VERSION ]; then PG_VERSION=11; fi
if [ ! -v PG_PASSWORD ]; then PG_PASSWORD='YuiXQlk_d@WushaIDO@as^asSIOus'; fi
if [ ! -v PG_ALLOW_REMOTE_CONNECTIONS ]; then PG_ALLOW_REMOTE_CONNECTIONS=yes; fi

sudo apt-get update -y
sudo apt-get install curl ufw apt-transport-https -y

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ ${OS_CODENAME}-pgdg main"

# install postgresql
sudo apt-get update -y
sudo apt-get install postgresql-${PG_VERSION} -y

if [ "$PG_VERSION" == "9.4" ] || [ "$PG_VERSION" == "9.5" ] || [ "$PG_VERSION" == "9.6" ]; then
  sudo apt-get install postgresql-contrib-${PG_VERSION} -y
fi

# restart service
sudo service postgresql restart

# set the postgres user password
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$PG_PASSWORD';"

# enable remote connections
if [ "$PG_ALLOW_REMOTE_CONNECTIONS" == "yes" ]; then
  sudo sed -i "s/^#listen_addresses.*/listen_addresses = '*'/g" /etc/postgresql/${PG_VERSION}/main/postgresql.conf
  if [[ -z $(sudo grep "0.0.0.0/0" /etc/postgresql/${PG_VERSION}/main/pg_hba.conf) ]]; then 
    echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
  fi
  if [[ -z $(sudo grep "::0/0" /etc/postgresql/${PG_VERSION}/main/pg_hba.conf) ]]; then 
    echo "host    all             all             ::0/0                   md5" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
  fi
fi

# restart service
sudo service postgresql restart

if [ "$PG_ALLOW_REMOTE_CONNECTIONS" == "yes" ]; then
  sudo ufw allow 5432
  sudo ufw allow 5432/tcp
  sudo ufw reload
  sudo ufw --force enable
fi

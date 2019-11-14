!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# The following variables are the defaults, modify as needed
# export SQLSERVER_PASSWORD='YuiXQlk_d@WushaIDO@as^asSIOus'  # required
# export SQLSERVER_VERSION=2019  # possible options: 2017, 2019
# export SQLSERVER_EDITION=Express  # possible options: Evaluation, Developer, Enterprise, Standard, Web, and Express
# export SQLSERVER_INSTALL_SQLAGENT=yes # options: no, yes
# export SQLSERVER_INSTALL_FULLTEXT=yes # options: no, yes
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-sqlserver.sh | bash
# -----------------------------

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')

if [ "$OS_VERSION" != "16.04" ]; then
  echo 'Only Ubuntu 16.04 is supported at this time.'
  exit 0
fi

if [ ! -v SQLSERVER_VERSION ]; then SQLSERVER_VERSION=2019; fi
if [ ! -v SQLSERVER_EDITION ]; then SQLSERVER_VERSION=Express; fi
if [ ! -v SQLSERVER_PASSWORD ]; then SQLSERVER_PASSWORD='YuiXQlk_d@WushaIDO@as^asSIOus'; fi
if [ ! -v SQLSERVER_INSTALL_SQLAGENT ]; then SQLSERVER_INSTALL_SQLAGENT=yes; fi
if [ ! -v SQLSERVER_INSTALL_FULLTEXT ]; then SQLSERVER_INSTALL_FULLTEXT=yes; fi

sudo apt-get update -y
sudo apt-get install curl ufw -y

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-${SQLSERVER_VERSION}.list)"
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

# install sqlserver
sudo apt-get update -y
sudo apt-get install mssql-server -y
sudo MSSQL_SA_PASSWORD=$SQLSERVER_PASSWORD \
     MSSQL_PID=$SQLSERVER_EDITION \
     ACCEPT_EULA=Y \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

# install sqlserver commmandline tools
sudo ACCEPT_EULA=Y apt-get install mssql-tools unixodbc-dev -y

# add commandline tools to bash profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# install sqlagent
if [ "$SQLSERVER_INSTALL_SQLAGENT" == "yes" ]; then
  sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
  sudo systemctl restart mssql-server
fi

# install fulltext search
if [ "$SQLSERVER_INSTALL_FULLTEXT" == "yes" ]; then
  sudo apt-get install mssql-server-fts -y
fi

sudo systemctl restart mssql-server
 
sudo ufw allow 1433
sudo ufw allow 1433/tcp
sudo ufw reload
sudo ufw --force enable

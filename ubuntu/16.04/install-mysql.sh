#!/bin/sh

# a great set of instructions also available here:
# https://www.rosehosting.com/blog/install-cockpit-on-ubuntu-16-04/

MYSQL_PASSWORD=root

sudo apt-get update && sudo apt-get -y upgrade

# Set the Server Timezone to CST
echo "America/Chicago" > /etc/timezone
sudo dpkg-reconfigure -f noninteractive tzdata

# Install essential packages
sudo apt-get -y install zsh htop

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
sudo apt-get -y install mysql-server

# Install mysql (although not necessary for Cockpit CMS which uses sqlite instead)
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASSWORD'
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD'
# sudo apt-get -y install mysql-server

sudo apt-get -y install ufw
sudo ufw allow ssh
sudo ufw allow 3306
sudo ufw --force enable

# further secure the mysql install
# this is for MySQL 5.7
sudo apt-get -y install aptitude
sudo aptitude -y install expect

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter password for user root:\"
send \"$MYSQL_PASSWORD\r\"
expect \"Would you like to setup VALIDATE PASSWORD plugin?\"
send \"n\r\" 
expect \"Change the password for root ?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

sudo aptitude -y purge expect

sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
cat >~/.my.cnf <<EOL
[client]
user=root
password=$MYSQL_PASSWORD
EOL

chmod 600 ~/.my.cnf

mysql -u root -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

sudo service mysql restart



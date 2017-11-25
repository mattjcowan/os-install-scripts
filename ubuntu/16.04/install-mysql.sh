#!/bin/sh

# a great set of instructions also available here:
# https://www.rosehosting.com/blog/install-cockpit-on-ubuntu-16-04/

MYSQL_PASSWORD=Pa$$w0rd

sudo apt-get update && sudo apt-get -y upgrade

# Install mysql (although not necessary for Cockpit CMS which uses sqlite instead)
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASSWORD'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD'
sudo apt-get update
sudo apt-get -y install mysql-server

# further secure the mysql install with
# mysql_secure_installation

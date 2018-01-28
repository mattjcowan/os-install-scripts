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
sudo apt-get install ufw -y
sudo apt-get install python-pip -y

# Configure Firewall
# See also:
# - https://www.vultr.com/docs/how-to-configure-ufw-firewall-on-ubuntu-14-04
# -----------------------------
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
# OR allow only specific IPs
# sudo ufw deny ssh
# sudo ufw allow from 192.168.0.1 to any port 22
sudo ufw --force enable

# Upgrade pip
# -----------------------------
pip install --upgrade pip
pip install setuptools

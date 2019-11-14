!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# The following variables are the defaults, modify as needed
# export DOTNET_VERSION=3.0  # possible options: 2.2, 3.0
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-dotnet.sh | bash
# -----------------------------

if [ ! -v DOTNET_VERSION ]; then DOTNET_VERSION=3.0; fi

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')

wget -q https://packages.microsoft.com/config/ubuntu/$OS_VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

if [ "$OS_VERSION" == "18.04" ]; then
  sudo add-apt-repository universe
fi

sudo apt-get update -y
sudo apt-get install apt-transport-https -y

sudo dpkg --purge packages-microsoft-prod && sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update -y
sudo apt-get install dotnet-sdk-${DOTNET_VERSION} -y

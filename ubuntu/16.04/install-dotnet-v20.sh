#!/bin/sh

# Install dotnet core pre-requisites
# see: https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x

sudo apt-get install libunwind8 -y
sudo apt-get install liblttng-ust0 -y
sudo apt-get install libcurl3 -y
sudo apt-get install libssl1.0.0 -y
sudo apt-get install libuuid1 -y
sudo apt-get install libkrb5 -y
sudo apt-get install zlib1g -y
sudo apt-get install libicu55 -y

# Register the Microsoft Product key as trusted
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

# Set up the desired version host package feed.
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update

# Install .NET core (for some reasons there are issues here with timing, and even a sleep after this doesn't quite work)
# Hosting only (no build tools) 
# sudo apt-get install dotnet-hosting-2.0.4 -y
# SDK (includes build tools)
sudo apt-get install dotnet-sdk-2.0.4 -y

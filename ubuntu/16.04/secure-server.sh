#!/bin/sh

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# export NEW_USER=remoteuser
# export NEW_PASSWORD=3up3eR$raz7p0sswR4d
# export PERMIT_ROOT_LOGIN=no  # options: no, prohibit-password (default)
# DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
# curl $DOWNLOAD_URL_BASE/secure-server.sh | bash
# -----------------------------

if [ ! -v NEW_USER ]; then
  NEW_USER=remoteuser
fi

if [ ! -v NEW_PASSWORD ]; then
  NEW_PASSWORD=3up3eR$raz7p0sswR4d
fi

if [ ! -v PERMIT_ROOT_LOGIN ]; then
  PERMIT_ROOT_LOGIN=prohibit-password
fi

if [ ! -d /home/${NEW_USER}/.ssh ]; then
  useradd -m -p $(openssl passwd -1 ${NEW_PASSWORD}) -s /bin/bash -G sudo ${NEW_USER}
  gpasswd -a ${NEW_USER} sudo
  mkdir /home/${NEW_USER}/.ssh
  chmod 700 /home/${NEW_USER}/.ssh
  cat ~/.ssh/authorized_keys >> /home/${NEW_USER}/.ssh/authorized_keys
  chown ${NEW_USER}:${NEW_USER} /home/${NEW_USER} -R
fi

sed -i 's/#ChallengeResponseAuthentication/ChallengeResponseAuthentication/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sed -i 's/#UsePAM/UsePAM/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication/PubkeyAuthentication/g' /etc/ssh/sshd_config

# disable password authentication
# disable root login with password (still allow SSH key auth)
sshd_config_file=/etc/ssh/sshd_config
cp -p $sshd_config_file $sshd_config_file.old &&
while read key other
do
 case $key in
 ChallengeResponseAuthentication) other=no;;
 PasswordAuthentication) other=no;;
 UsePAM) other=no;;
 PermitRootLogin) other=$PERMIT_ROOT_LOGIN;;
 PubkeyAuthentication) other=yes;;
 esac
 echo "$key $other"
done < $sshd_config_file.old > $sshd_config_file

service ssh restart

!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# Tested on Ubuntu 16.04, 18.04, 19.04, and 20.04
# -----------------------------
# The following variables are the defaults, modify as needed
# export NEW_USER=remoteuser
# export NEW_PASSWORD=3up3eR@raz7p0sswR4d
# export PERMIT_ROOT_LOGIN=prohibit-password  # options: no, prohibit-password (default)
# export PERMIT_PASSWORD_LOGIN=yes # options: no, yes (default)
# export SUDO_WITHOUT_PASSWORD=no #options: yes, no (default)
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/server-setup.sh | bash
# -----------------------------

touch /root/trash 2> /dev/null
if [  $? -ne  0  ]; then 
  echo "Execute this script as the root user ..."
  exit 0;
fi
   
if [ ! -v NEW_USER ]; then NEW_USER=remoteuser; fi
if [ ! -v NEW_PASSWORD ]; then NEW_PASSWORD=3up3eR@raz7p0sswR4d; fi
if [ ! -v PERMIT_ROOT_LOGIN ]; then PERMIT_ROOT_LOGIN=prohibit-password; fi
if [ ! -v PERMIT_PASSWORD_LOGIN ]; then PERMIT_PASSWORD_LOGIN=yes; fi
if [ ! -v SUDO_WITHOUT_PASSWORD ]; then SUDO_WITHOUT_PASSWORD=no; fi

# apply system updates
apt-get update -y
apt-get upgrade -y

# install popular packages
apt-get install ufw curl git openssl autoremove unattended-upgrades -y

# set the default shell for users
useradd -Ds /bin/bash

# create the user and the user's home directory if it doesn't exist
if [ ! -d /home/${NEW_USER} ]; then
  useradd -m -p $(openssl passwd -1 ${NEW_PASSWORD}) -s /bin/bash -G sudo ${NEW_USER}
  gpasswd -a ${NEW_USER} sudo
fi

# create an `admin` group if it doesn't exist, and add the user to it
groupadd -f admin && usermod -aG admin $NEW_USER

# setup user's ssh environment, copy root's authorized keys and generate an ssh key pair
if [ ! -d /home/${NEW_USER}/.ssh ]; then
  mkdir /home/${NEW_USER}/.ssh
  pushd /home/${NEW_USER}/.ssh
    cat ~/.ssh/authorized_keys >> /home/${NEW_USER}/.ssh/authorized_keys
    ssh-keygen -f id_rsa -t rsa -N '' -C "${NEW_USER}@${NEW_USER}.me"
  popd
fi

# ensure directory permissions are correct
chmod 700 /home/${NEW_USER}/.ssh
chmod 600 /home/${NEW_USER}/.ssh/authorized_keys
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}

# disable root login with password, or alltogether
sed -i "s/#PermitRootLogin/PermitRootLogin/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*/PermitRootLogin $PERMIT_ROOT_LOGIN/g" /etc/ssh/sshd_config

# disable password login
if [ "$PERMIT_PASSWORD_LOGIN" == "no" ]; then
  sshd_no_keys=(PasswordAuthentication ChallengeResponseAuthentication UsePAM)
  for i in "${sshd_no_keys[@]}"; do
    sed -i "s/#$i/$i/g" /etc/ssh/sshd_config
    sed -i "s/^$i.*/$i no/g" /etc/ssh/sshd_config
  done
fi

# disable sudo with password
if [ "$SUDO_WITHOUT_PASSWORD" == "yes" ]; then
  if grep -Fwq "$NEW_USER" /etc/sudoers; then 
    echo 'Rule already exists in /etc/sudoers'; 
  else 
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo "" >> /etc/sudoers
  fi
fi

# restart sshd
systemctl restart sshd

# allow ssh through the firewall
ufw disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable
ufw reload

# setup autoupgrades, and remove extraneous packages
apt-get autoremove -y
cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "3";
APT::Periodic::Unattended-Upgrade "1";
EOL

echo "Unattended-Upgrade::Automatic-Reboot \"true\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
echo "Unattended-Upgrade::Automatic-Reboot-Time \"07:00\";" | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades

# install fail2ban
apt install fail2ban -y
cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fail2ban-client start

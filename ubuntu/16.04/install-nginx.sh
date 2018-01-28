#!/bin/sh

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
# curl $DOWNLOAD_URL_BASE/install-common-libraries.sh | bash
# curl $DOWNLOAD_URL_BASE/install-nginx.sh | bash
# -----------------------------

sudo apt-get install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw reload

# --> start Nginx
# sudo systemctl start nginx

# --> stop Nginx
# sudo systemctl stop nginx

# --> restart Nginx
# sudo systemctl restart nginx

# --> reload Nginx configuration without dropping connections
# sudo systemctl reload nginx

# --> start Nginx at server boot.
# sudo systemctl enable nginx

# --> prevent Nginx from starting at server boot
# sudo systemctl disable nginx

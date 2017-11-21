#!/bin/sh

# This script works with the 'install-aspnet-core-webapp.sh' script

# Get public IP for this server
publicip="$(dig +short myip.opendns.com @resolver1.opendns.com)"

# Install nginx: https://docs.microsoft.com/en-us/aspnet/core/publishing/linuxproduction?tabs=aspnetcore2x
sudo apt-get install nginx -y
sudo service nginx start

# Overwrite nginx file
cat >/etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# reload nginx 
sudo nginx -s reload

# GO FURTHER, add a self-signed cert with 443 and SSL (works with cloudflare)

# create a self-signed certificate
# see: https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj /C=US/ST=Illinois/L=Chicago/O=Startup/CN=$publicip
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 > /dev/null 2>&1

cat >/etc/nginx/snippets/self-signed.conf <<EOL
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOL

cat >/etc/nginx/snippets/ssl-params.conf <<EOL
# from https://cipherli.st/
# and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
ssl_dhparam /etc/ssl/certs/dhparam.pem;
EOL

# Before we go any further, let's back up our current server block file:
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

cat >/etc/nginx/sites-available/default <<EOL
server {
    # SSL configuration
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name $publicip;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# restart nginx
sudo systemctl restart nginx

# improve nginx further
# see: https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-with-http-2-support-on-ubuntu-16-04

# setup firewall: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-16-04
sudo apt-get install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable -y

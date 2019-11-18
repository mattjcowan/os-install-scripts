!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# export APP_SERVICE_NAME=aspnetapp # required: the systemd service name
# export APP_UPSTREAM_HOSTS=()
# export APP_DEFAULT_SERVER=yes
# export APP_SERVER_NAME=_
# export APP_CSP_HOSTS="https://ssl.google-analytics.com https://fonts.googleapis.com https://themes.googleusercontent.com https://cdn.jsdelivr.net https://maxcdn.bootstrapcdn.com https://code.jquery.com https://cdnjs.cloudflare.com"
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-nginx-lb.sh | bash
# -----------------------------

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')

if [ ! -v APP_SERVICE_NAME ]; then
  echo "app name is required (APP_SERVICE_NAME)"
  exit 1
fi

if [ ! -v APP_UPSTREAM_HOSTS ]; then
  echo "upstream hosts are required (APP_UPSTREAM_HOSTS)"
  exit 1
fi

if [ ! -v APP_DEFAULT_SERVER ]; then APP_DEFAULT_SERVER=yes; fi
if [ ! -v APP_SERVER_NAME ]; then APP_SERVER_NAME=_; fi
if [ ! -v APP_CSP_HOSTS ]; then APP_CSP_HOSTS="https://ssl.google-analytics.com https://fonts.googleapis.com https://themes.googleusercontent.com https://cdn.jsdelivr.net https://maxcdn.bootstrapcdn.com https://code.jquery.com https://cdnjs.cloudflare.com"; fi

sudo apt-get update -y 
sudo apt-get upgrade -y
sudo apt-get install nginx openssl dnsutils -y

sudo systemctl start nginx
sudo systemctl enable nginx

# install firewall
sudo apt-get install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw reload
sudo ufw --force enable

# create nginx self-signed certs
[[ -f /etc/ssl/openssl.cnf ]] && sudo sed -i 's/^RANDFILE/#&/' /etc/ssl/openssl.cnf

if [[ ! -f /etc/ssl/private/nginx-selfsigned.key || ! -f /etc/ssl/certs/nginx-selfsigned.crt ]]; then
sudo openssl req -x509 -nodes -days 2000 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj /C=US/ST=Illinois/L=Chicago/O=Startup/CN=$APP_SERVICE_NAME
fi

if [[ ! -f /etc/ssl/certs/dhparam.pem ]]; then
sudo openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 2048 > /dev/null 2>&1
fi

if [[ ! -f /etc/nginx/snippets/ssl-params.conf ]]; then
sudo bash -c 'cat >/etc/nginx/snippets/ssl-params.conf' <<EOL
ssl_protocols TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=30;
resolver_timeout 5s;
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
ssl_dhparam /etc/ssl/certs/dhparam.pem;
EOL
fi

if [[ ! -f /etc/nginx/snippets/self-signed.conf || ! -f /etc/ssl/certs/nginx-selfsigned.crt ]]; then
sudo bash -c 'cat >/etc/nginx/snippets/self-signed.conf' <<EOL
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOL
fi

DEFSVR=""
if [ "$APP_DEFAULT_SERVER" == "yes" ]; then DEFSVR="default_server"; fi

# create nginx site mapping
if [ ! -f /etc/nginx/sites-available/$APP_SERVICE_NAME ]; then
sudo bash -c "cat >/etc/nginx/sites-available/$APP_SERVICE_NAME" <<EOL
upstream upstreamconnections {
    server 10.1.96.1:443;
    server 10.1.96.2:443;
    server 10.1.96.3:443;
    server 10.1.96.4:443;
    server 10.1.96.5:443;
}
server {
    # force https
    listen 80 $DEFSVR;
    listen [::]:80 $DEFSVR;
    server_name $APP_SERVER_NAME;
    return 301 https://$host$request_uri;
}
server {
    client_max_body_size 500M;

    listen 443 ssl http2 $DEFSVR;
    listen [::]:443 ssl http2 $DEFSVR;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;
    server_tokens off;
    server_name $APP_SERVER_NAME;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    # reverse proxy to api, hosted by systemd service
    location / {
        proxy_pass https://upstreamconnections;
        proxy_ssl_verify off;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
fi

if [[ -f /etc/nginx/sites-enabled/default ]]; then
  sudo rm /etc/nginx/sites-enabled/default
fi

if [[ ! -f /etc/nginx/sites-enabled/$APP_SERVICE_NAME ]]; then
  sudo ln -s /etc/nginx/sites-available/$APP_SERVICE_NAME /etc/nginx/sites-enabled/$APP_SERVICE_NAME
fi

# start the service
sudo service nginx reload

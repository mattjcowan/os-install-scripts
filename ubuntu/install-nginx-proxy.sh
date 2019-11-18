!/usr/bin/env bash

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# export APP_SERVICE_NAME=aspnetapp # required: the systemd service name
# export APP_PROXY_PASS=http://localhost:5000 # required: the url for nginx to proxy to
# export APP_SERVICE_EXECSTART=/var/www/aspnetapp/dist/app # required: the systemd ExecStart command to run
# export APP_SERVICE_WORKINGDIR=/var/www/aspnetapp/dist # required: the systemd location of the app
# export APP_SERVICE_ENV=(ASPNETCORE_ENVIRONMENT=Production DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_PRINT_TELEMETRY_MESSAGE=false) # optional: array of systemd service environment variables
# export APP_DIR=$APP_SERVICE_WORKINGDIR
# export APP_DEFAULT_SERVER=yes # options: no, yes (default)
# export APP_SERVER_NAME=_
# export APP_CSP_HOSTS="https://ssl.google-analytics.com https://fonts.googleapis.com https://themes.googleusercontent.com https://cdn.jsdelivr.net https://maxcdn.bootstrapcdn.com https://code.jquery.com https://cdnjs.cloudflare.com"
# wget -O - https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/install-nginx-proxy.sh | bash
# -----------------------------

OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')

if [ ! -v APP_SERVICE_NAME ]; then
  echo "systemd service name is required (APP_SERVICE_NAME)"
  exit 1
fi

if [ ! -v APP_PROXY_PASS ]; then
  echo "url for nginx to proxy to is required (APP_PROXY_PASS)"
  exit 1
fi

if [ ! -v APP_SERVICE_EXECSTART ]; then
  echo "systemd service ExecStart is required (APP_SERVICE_EXECSTART)"
  exit 1
fi

if [ ! -v APP_SERVICE_NAME ]; then
  echo "systemd service working dir is required (APP_SERVICE_WORKINGDIR)"
  exit 1
fi

if [ ! -v APP_SERVICE_ENV ]; then APP_SERVICE_ENV=(ASPNETCORE_ENVIRONMENT=Production DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_PRINT_TELEMETRY_MESSAGE=false); fi
if [ ! -v APP_DIR ]; then APP_DIR=$APP_SERVICE_WORKINGDIR; fi
if [ ! -v APP_DEFAULT_SERVER ]; then APP_DEFAULT_SERVER=yes; fi
if [ ! -v APP_SERVER_NAME ]; then APP_SERVER_NAME=_; fi
if [ ! -v APP_CSP_HOSTS ]; then APP_CSP_HOSTS="https://ssl.google-analytics.com https://fonts.googleapis.com https://themes.googleusercontent.com https://cdn.jsdelivr.net https://maxcdn.bootstrapcdn.com https://code.jquery.com https://cdnjs.cloudflare.com"; fi

# update server libraries
sudo apt-get update -y

# install firewall
sudo apt-get install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable

# install nginx
sudo apt-get install nginx openssl -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw reload

# create nginx self-signed certs
sudo apt-get install dnsutils -y
[[ -f /etc/ssl/openssl.cnf ]] && sudo sed -i 's/^RANDFILE/#&/' /etc/ssl/openssl.cnf

# publicip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
if [[ ! -f /etc/ssl/private/nginx-selfsigned.key || ! -f /etc/ssl/certs/nginx-selfsigned.crt ]]; then
sudo openssl req -x509 -nodes -days 2000 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj /C=US/ST=Illinois/L=Chicago/O=Startup/CN=$APP_SERVER_NAME
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

if [[ ! -f /etc/nginx/snippets/self-signed.conf ]]; then
sudo bash -c 'cat >/etc/nginx/snippets/self-signed.conf' <<EOL
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOL
fi

DEFSVR=""
if [ "$APP_DEFAULT_SERVER" == "yes" ]; then DEFSVR="default_server"; fi

# create nginx site mapping
# if [ ! -f /etc/nginx/sites-available/$APP_SERVICE_NAME ]; then
sudo bash -c "cat >/etc/nginx/sites-available/$APP_SERVICE_NAME" <<EOL
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
    root $APP_DIR;

    # enable the following if SPA app, and if NGINX should serve html default files
    #index index.html index.htm default.html default.htm;

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    # reverse proxy to api, hosted by systemd service
    location / {
        proxy_pass $APP_PROXY_PASS;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
        proxy_ignore_client_abort off;
        proxy_intercept_errors on;
        proxy_pass_request_headers on;

        proxy_hide_header X-Content-Type-Options;

        # The following are needed for a perfect security score
        # get a grade A in security at https://securityheaders.io
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        #add_header X-Content-Type-Options "" always;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload";
        add_header Content-Security-Policy "default-src https: 'self' $APP_CSP_HOSTS; script-src https: 'self' 'unsafe-inline' 'unsafe-eval' $APP_CSP_HOSTS; img-src https: 'self' data: $APP_CSP_HOSTS; style-src 'self' 'unsafe-inline' $APP_CSP_HOSTS; font-src https: 'self' $APP_CSP_HOSTS; frame-src $APP_CSP_HOSTS; object-src 'none'";
        add_header Referrer-Policy "no-referrer";
    }

    # If the following is enabled, these extensions will not be served by the proxy
    # location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    #     expires max;
    #     log_not_found off;
    # }
}
EOL
# fi

if [[ ! -f /etc/nginx/sites-enabled/default ]]; then
  rm /etc/nginx/sites-enabled/default
fi

if [[ ! -f /etc/nginx/sites-enabled/$APP_SERVICE_NAME ]]; then
sudo ln -s /etc/nginx/sites-available/$APP_SERVICE_NAME /etc/nginx/sites-enabled/$APP_SERVICE_NAME
fi

# create system.d service
# if [[ ! -f /etc/systemd/system/$APP_SERVICE_NAME.service ]]; then
sudo bash -c "cat >/etc/systemd/system/$APP_SERVICE_NAME.service" <<EOL
[Install]
WantedBy=multi-user.target
[Unit]
Description=$APP_SERVICE_NAME
[Service]
WorkingDirectory=$APP_SERVICE_WORKINGDIR
ExecStart=$APP_SERVICE_EXECSTART
Restart=always
RestartSec=10
SyslogIdentifier=$APP_SERVICE_NAME
User=www-data
EOL

for i in ${APP_SERVICE_ENV[@]}
do
  echo "Environment=$i" | sudo tee -a /etc/systemd/system/$APP_SERVICE_NAME.service
done
# fi

# fix permissions
sudo find /var/www/ -type d -exec chmod 755 {} \;
sudo find /var/www/ -type f -exec chmod 644 {} \;
sudo chown -R www-data:www-data /var/www/
sudo find $APP_SERVICE_WORKINGDIR -type d -exec chmod 755 {} \;
sudo find $APP_SERVICE_WORKINGDIR -type f -exec chmod 644 {} \;
sudo chown -R www-data:www-data $APP_SERVICE_WORKINGDIR

# make the start command executable if it's a file
[[ -f $APP_SERVICE_EXECSTART ]] && sudo chmod +x $APP_SERVICE_EXECSTART

# start the service
sudo service nginx reload
sudo systemctl enable $APP_SERVICE_NAME.service
sudo service $APP_SERVICE_NAME stop
sudo service $APP_SERVICE_NAME start

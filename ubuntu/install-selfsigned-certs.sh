
!/usr/bin/env bash

sudo apt-get install openssl

if [[ ! -f /etc/ssl/certs/dhparam.pem ]]; then
sudo openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096 > /dev/null 2>&1
fi

if [[ ! -f /etc/ssl/private/nginx-selfsigned.key || ! -f /etc/ssl/certs/nginx-selfsigned.crt ]]; then
# Generate a passphrase
cd ~/
sudo openssl rand -base64 48 > passphrase.txt
# Generate a Private Key
sudo openssl genrsa -aes128 -passout file:passphrase.txt -out server.key 2048
# Generate a CSR (Certificate Signing Request)
sudo openssl req -new -passin file:passphrase.txt -key server.key -out server.csr \
    -subj "/C=US/ST=Illinois/L=Chicago/O=Startup/CN=ServerApp"
# Remove Passphrase from Key
sudo cp server.key server.key.org
sudo openssl rsa -in server.key.org -passin file:passphrase.txt -out server.key
# Generating a Self-Signed Certificate for 100 years
sudo openssl x509 -req -days 36500 -in server.csr -signkey server.key -out server.crt

# Rename and move the certs to a good destination
sudo mkdir -p /etc/nginx/ssl
sudo mkdir -p /etc/nginx/ssl/private
sudo chmod 755 /etc/nginx/ssl
sudo chmod 710 /etc/nginx/ssl/private

sudo mv server.crt /etc/nginx/ssl/certs/nginx-selfsigned.crt
sudo mv server.key /etc/nginx/ssl/private/nginx-selfsigned.key

sudo chown -R root:root /etc/nginx/ssl/
sudo chown -R root:ssl-cert /etc/nginx/ssl/private/
sudo chmod 644 /etc/nginx/ssl/*.crt
sudo chmod 640 /etc/nginx/ssl/private/*.key
fi

# Create snippet for easy integration to new sites
if [[ ! -f /etc/nginx/snippets/ssl-params.conf ]]; then
sudo bash -c 'cat >/etc/nginx/snippets/ssl-params.conf' <<EOL
gzip off;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;
ssl_dhparam /etc/nginx/ssl/certs/dhparam.pem;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_ecdh_curve secp384r1;

ssl_stapling on;
ssl_stapling_verify on;

resolver 8.8.8.8 8.8.4.4 valid=30;
resolver_timeout 5s;
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
EOL
fi

if [[ ! -f /etc/nginx/snippets/ssl-selfsigned.conf ]]; then
sudo bash -c 'cat >/etc/nginx/snippets/ssl-selfsigned.conf' <<EOL
ssl_certificate /etc/nginx/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/nginx/ssl/private/nginx-selfsigned.key;
EOL
fi

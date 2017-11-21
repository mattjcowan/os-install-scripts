#!/bin/sh

# Create sample app if it does not exist
if [ ! -d /var/www/webapp ]; then
    cd /home/
    mkdir apps
    cd /home/apps

    # Create app
    dotnet new web --name WebApp --output webapp
    cd webapp
    dotnet restore
    dotnet build
    dotnet publish -c Release -o dist
    
    # deploy the webapp
    sudo mv dist/ /var/www/webapp
fi

# create system.d service
cat >/etc/systemd/system/kestrel-webapp.service <<EOL
[Unit]
Description=WebApp Kestrel Service
[Service]
WorkingDirectory=/var/www/webapp
ExecStart=/usr/bin/dotnet /var/www/webapp/WebApp.dll
Restart=always
RestartSec=10
SyslogIdentifier=dotnet-webapp
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
[Install]
WantedBy=multi-user.target
EOL

# enable the service to start after system restarts
systemctl enable kestrel-webapp.service

# start the service and check status
systemctl start kestrel-webapp.service
systemctl status kestrel-webapp.service

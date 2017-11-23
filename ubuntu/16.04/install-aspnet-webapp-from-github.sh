#!/bin/sh

# EDIT THE FOLLOWING 3 LINES FOR A PUBLIC GITHUB REPO
GITHUB_REPO_NAME=SuperSimpleWeb/ssw-starterkit
CSPROJ_REPO_DIR=webapp
ASSEMBLY_NAME=WebApp.dll

GITHUB_REPO_URL=https://github.com/$GITHUB_REPO_NAME
SCRIPT_DIR=/home/apps
LOCAL_DIR=$SCRIPT_DIR/$GITHUB_REPO_NAME
CSPROJ_DIR=$SCRIPT_DIR/$GITHUB_REPO_NAME/$CSPROJ_REPO_DIR
DEPLOY_DIR=/var/www/webapp

# Create sample app if it does not exist
# You could also pull down a git repository if you want
if [ ! -d $LOCAL_DIR ]; then
    mkdir -p $LOCAL_DIR
    cd $LOCAL_DIR
    git clone -b master $GITHUB_REPO_URL .
fi

if [ ! -d $DEPLOY_DIR ]; then
    cd $CSPROJ_DIR

    # Create app
    dotnet restore
    dotnet build
    dotnet publish -c Release -o $SCRIPT_DIR/dist
    
    # deploy the webapp
    sudo mv $SCRIPT_DIR/dist/ $DEPLOY_DIR
fi

# create system.d service
cat >/etc/systemd/system/kestrel-webapp.service <<EOL
[Unit]
Description=WebApp Kestrel Service
[Service]
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/dotnet $DEPLOY_DIR/$ASSEMBLY_NAME
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

# Monitor the status of the service using (beware, this keeps the terminal open)
# systemctl status kestrel-webapp.service

# create cronjob that checks every minute for changes and rebuilds the app
cat >$SCRIPT_DIR/webapp.refresh.sh <<EOL
cd $LOCAL_DIR
changed=0
git remote update && git status -uno | grep -q 'Your branch is behind' && changed=1
if [ \$changed = 1 ]; then
    git pull
    cd $CSPROJ_DIR
    dotnet restore
    dotnet build
    dotnet publish -c Release -o $SCRIPT_DIR/dist
    rsync -r $SCRIPT_DIR/dist/ $DEPLOY_DIR
    systemctl try-restart kestrel-webapp.service
    echo "Updated successfully";
else
    echo "Up to date"
fi
EOL
chmod +x $SCRIPT_DIR/webapp.refresh.sh

# create a cron job that runs every minute and runs the script above (make sure you leave the last line empty)
cat >/etc/cron.d/refresh_webapp_every_minute <<EOL
* * * * * root /bin/sh $SCRIPT_DIR/webapp.refresh.sh > $SCRIPT_DIR/webapp.refresh.log 2>&1

EOL



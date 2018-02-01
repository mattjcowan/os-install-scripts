#!/bin/sh

# -----------------------------
# INSTRUCTIONS
# -----------------------------
# !! required
# export REPO_URL=repo_url  # include username:password if it's a private repo (i.e.: https://username:Passw%40rd@github.com/org/repo.git)
#
# !! optional
# export APP_NAME=name_of_app_or_csproj # name of app (will default to 'webapp') !! WARNING, in the case of a .net app, this should be the name of the assembly to run
# export REPO_BRANCH=master # the branch that should be deployed (defaults to 'master')
# export BUILD_DIR=src # defaults to ./ (directory where the build command should be run from)
# export BUILD_CMD=cd src && npm run build # defaults to ./build.sh or ./scripts/build.sh or npm run build (if there's a package.json file) or dotnet restore/build/publish if there's a csproj file (in that order)
# export PUBLISH_DIR=dist/ # defaults to 'dist/'
# export DEPLOY_DIR=/var/www/webapp # defaults to /var/www/$APP_NAME
#
# DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
# curl $DOWNLOAD_URL_BASE/install-common-libraries.sh | bash
# curl $DOWNLOAD_URL_BASE/install-nginx.sh | bash
# curl $DOWNLOAD_URL_BASE/install-node-v8.sh | bash
# curl $DOWNLOAD_URL_BASE/install-dotnet-v20.sh | bash
# curl $DOWNLOAD_URL_BASE/autodeploy-git-repo.sh | bash
# -----------------------------

if [ ! -v APP_NAME ]; then APP_NAME=webapp; fi
if [ ! -v REPO_BRANCH ]; then REPO_BRANCH=master; fi

SCRIPT_DIR=/home/apps
LOCAL_DIR=$SCRIPT_DIR/$APP_NAME

# create a home directory for cloned repos
if [ ! -d $SCRIPT_DIR ]; then mkdir $SCRIPT_DIR; fi

# clone the repo if it hasn't already been cloned
if [ ! -d $LOCAL_DIR ]; then
    mkdir -p $LOCAL_DIR
    cd $LOCAL_DIR
    git clone -b $REPO_BRANCH $REPO_URL .
fi

# set the publish directory
if [ ! -v PUBLISH_DIR ]; then PUBLISH_DIR=dist/; fi
PUBLISH_DIR=$LOCAL_DIR/$PUBLISH_DIR

# set the build directory
if [ ! -v BUILD_DIR ]; then BUILD_DIR=""; fi
BUILD_DIR=$LOCAL_DIR/$BUILD_DIR

# detect csproj & prefer one matching the $APP_NAME variable
if [ -f $BUILD_DIR/$APP_NAME.csproj ]; then CSPROJ=$APP_NAME.csproj; fi
if [ ! -v CSPROJ ]; then
  shopt -s nullglob
  set -- $BUILD_DIR/*.csproj
  CSPROJ="$1"
fi

# use a build.sh file if it exists
if [ ! -v BUILD_CMD ] && [ -f $BUILD_DIR/build.sh ]; then
  chmod +x $BUILD_DIR/build.sh
  BUILD_CMD=$BUILD_DIR/build.sh
  
# use a scripts/build.sh file if it exists
elif [ ! -v BUILD_CMD ] && [ -f $BUILD_DIR/scripts/build.sh ]; then 
  chmod +x $BUILD_DIR/scripts/build.sh
  BUILD_CMD=$BUILD_DIR/scripts/build.sh
  
# use a package.json file if it exists
elif [ ! -v BUILD_CMD ] && [ -f $BUILD_DIR/package.json ]; then 
  BUILD_CMD=npm run build
  
# use dotnet if a *.csproj exists
elif [ ! -v BUILD_CMD ] && [ $CSPROJ != "" ]; then 
  BUILD_CMD=dotnet publish $CSPROJ -c Release -o $PUBLISH_DIR
  
fi

# deploy the first time
if [ ! -d $DEPLOY_DIR ]; then
  cd $BUILD_DIR
  $BUILD_CMD
  sudo mv $PUBLISH_DIR $DEPLOY_DIR
fi

# if csproj && dotnet then create kestrel service
if [ $CSPROJ != "" ]; then
  #if systemctl -a | grep kestrel-webapp.service; then    
  #echo "Kestrel service exists";
  #else
  if [ ! -f /etc/systemd/system/kestrel-webapp.service ]; then
    # get the name of the assembly based on the csproj file name (assume the names are the same)
    ASSEMBLY_NAME=$(basename ${CSPROJ%.*}).dll
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
  fi

  # enable the service to start after system restarts
  systemctl enable kestrel-webapp.service

  # start the service
  systemctl start kestrel-webapp.service

  # Monitor the status of the service using (beware, this keeps the terminal open)
  # systemctl status kestrel-webapp.service
fi

# create cronjob that checks every minute for changes and rebuilds the app
cat >$SCRIPT_DIR/webapp.refresh.sh <<EOL
cd $LOCAL_DIR
changed=0
git remote update && git status -uno | grep -q 'Your branch is behind' && changed=1
if [ \$changed = 1 ]; then
    git pull
    cd $BUILD_DIR
    $BUILD_CMD
    systemctl stop kestrel-webapp.service
    rsync -r $PUBLISH_DIR/ $DEPLOY_DIR
    systemctl try-restart kestrel-webapp.service
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



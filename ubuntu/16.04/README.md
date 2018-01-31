# Install a variety of applications and utilities from the command line

- [Common libraries & utilities](#common-libraries--utilities)
- [Secure server](#secure-server)
- [Nginx](#nginx)
- [.NET Core (v203)](#net-core-v203)
- [Node v8.9.4](#node-v894)

## Scripts

Set a common base url before running any of the scripts

```shell
DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
```
### [Common libraries & utilities](https://github.com/mattjcowan/os-install-scripts/blob/master/ubuntu/16.04/install-common-libraries.sh)

Run this before any of the other scripts to ensure the most common utilities exist on your server

```shell
curl $DOWNLOAD_URL_BASE/install-common-libraries.sh | bash
```

### [Secure server](https://github.com/mattjcowan/os-install-scripts/blob/master/ubuntu/16.04/secure-server.sh)

- Creates a NON 'root' user 
- Gives the user ssh permissions
- Disables password authentication and root ssh login (if PERMIT_ROOT_LOGIN var is 'no')
- Copies the .ssh/authorized_keys to the new user for immediate ssh access

#### Script:

```shell
export NEW_USER=remoteuser
export NEW_PASSWORD=a_super_secret_password
export PERMIT_ROOT_LOGIN=no  # options: no, prohibit-password (default)
DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04
curl $DOWNLOAD_URL_BASE/secure-server.sh | bash
```

You can now ssh as this user ... ssh remoteuser@{server_ip}

### [Nginx](https://github.com/mattjcowan/os-install-scripts/blob/master/ubuntu/16.04/install-nginx.sh)

#### Prerequisites:

- [Common libraries & utilities](#common-libraries--utilities)

#### Script:

```shell
curl $DOWNLOAD_URL_BASE/install-nginx.sh | bash
```

### [.NET Core v2.0.3](https://github.com/mattjcowan/os-install-scripts/blob/master/ubuntu/16.04/install-dotnet-v20.sh)

#### Prerequisites:

- [Common libraries & utilities](#common-libraries--utilities)

#### Script:

```shell
curl $DOWNLOAD_URL_BASE/install-dotnet-v20.sh | bash
```

### [Node v8.9.4](https://github.com/mattjcowan/os-install-scripts/blob/master/ubuntu/16.04/install-node-v8.sh)

#### Prerequisites:

- [Common libraries & utilities](#common-libraries--utilities)

#### Script:

```shell
curl $DOWNLOAD_URL_BASE/install-node-v8.sh | bash
```

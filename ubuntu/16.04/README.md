# Install a variety of applications and utilities from the command line

- [Common libraries & utilities](#common-libraries--utilities)
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

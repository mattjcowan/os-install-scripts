# Ubuntu scripts

## Variety of ways to run the scripts

### Download and install at once

```shell
DOWNLOAD_URL=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04/install-node-v8.sh
curl $DOWNLOAD_URL | bash
```

### Download and save to file and run

```shell
DOWNLOAD_URL=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04/install-node-v8.sh
FILE_NAME=install-node-v8.sh
curl -o /tmp/$FILE_NAME $DOWNLOAD_URL
chmod +x /tmp/$FILE_NAME
/tmp/$FILE_NAME
```

### Schedule the file to run at a given time

```shell
DOWNLOAD_URL=https://raw.githubusercontent.com/mattjcowan/os-install-scripts/master/ubuntu/16.04/install-node-v8.sh
FILE_NAME=install-node-v8.sh
curl -o /tmp/$FILE_NAME $DOWNLOAD_URL
chmod +x /tmp/$FILE_NAME
echo /tmp/$FILE_NAME | at now + 1 minute
```

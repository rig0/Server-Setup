# Server Setup
*A re-upload of an old script*

***Make sure to run as root.***

## Prepare server for setup

```bash
apt update && apt dist-upgrade -y && apt install git -y
```

## Copy script to local server

```bash
curl https://rigslab.com/Rambo/Server-Setup/raw/branch/main/setup.sh -O setup.sh && chmod +x setup.sh 
```

## Launch server setup

```bash
./setup.sh server=SERVERNAME user=USERNAME usrkey=PUSHOVER_USER appkey=PUSHOVER_APP sshkey=YOUR_CLIENT_SSH_KEY
```

## Arguments

- **server:** Server identifier and hostname

- **user:** User to be created with sudo privelages

- **sshkey:** Your ssh client public sshkey 

- *usrkey*:* Pushover user api key

- *appkey*:* Pushover app api key

- *panel*:* Control panel to install (cloudpanel, tinycp, webmin, openvpn, steam)

*= Optional
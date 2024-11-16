# Server Setup

***Must be ran as root***

## Prepare server for setup

```bash
apt update && apt dist-upgrade -y && apt install curl git -y
```

## Copy script to local server

```bash
curl https://rigslab.com/Rambo/Server-Setup/raw/branch/main/setup.sh -O setup.sh && chmod +x setup.sh 
```

## Launch server setup

```bash
./setup.sh hostname=HOSTNAME user=USERNAME
```

## Arguments

- **hostname:** Hostname

- **user:** User to be created with sudo privelages

- *sshkey*:* Your ssh client public sshkey 

- *usrkey*:* Pushover user api key

- *appkey*:* Pushover app api key

- *panel*:* Control panel to install (cloudpanel, tinycp, webmin, dockge, openvpn, steam)

*= Optional
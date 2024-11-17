# Server Setup

***Must be ran as root***

## Copy and Install

```bash
curl -O https://rigslab.com/Rambo/Server-Setup/raw/branch/main/setup.sh && chmod +x setup.sh && ./setup.sh hostname=HOSTNAME user=USERNAME
```

## Arguments

- **hostname:** Hostname

- **user:** User to be created with sudo privelages

- *sshkey*:* Your ssh client public sshkey 

- *usrkey*:* Pushover user api key

- *appkey*:* Pushover app api key

- *panel*:* Control panel to install (cloudpanel, tinycp, webmin, dockge, openvpn, steam)

*= Optional
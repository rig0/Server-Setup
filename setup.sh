#!/bin/bash
#RAMBO SERVER SETUP SCRIPT 2024. [DEBIAN 9-12]


# Initiliaze possible arguments
user="" # username to create with sudo privelages
hostname="" # used as fqdn & notification title
sshkey="" # client public ssh key (optional)
usrkey="" # pushover user api key (optional)
appkey="" # pushover app api key (optional)
panel="" # control panel (optional)
proxmox="" # proxmox machine? 1 if true; else leave blank (optional)


# Loop through arguments
for arg in "$@"; do
  case $arg in
    user=*) 
      user="${arg#*=}"
      ;;
    hostname=*) 
      hostname="${arg#*=}"
      ;;
    sshkey=*) 
      sshkey="${arg#*=}"
      ;;
    usrkey=*) 
      usrkey="${arg#*=}"
      ;;
    appkey=*) 
      appkey="${arg#*=}"
      ;;
    panel=*) 
      panel="${arg#*=}"
      ;;
    proxmox=*) 
      proxmox="${arg#*=}"
      ;;
    *)
      # Ignore unknown arguments or handle them as needed
      ;;
  esac
done


# Check if required arguments are provided
if [[ -z $user || -z $hostname ]]; then
  printf "Usage: $0 user=username hostname=hostname usrkey=pushoveruserkey* appkey=pushoverappkey* panel=cloudpanel* proxmox=1* sshkey=yourpubkey* \n *=optional"
  exit 1
fi

#Bash styling
#BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"


printf "$ST Updating OS & Installing prerequisites \n $SB"
apt update && apt dist-upgrade -y
apt install sudo screen curl ufw openssl rsync cron neofetch -y

# Installing qemu-guest-agent if server is a proxmox machine
if [[ "$proxmox" -eq 1 ]]; then
  apt install qemu-guest-agent
fi

printf "$ST Creating Main User. Set your password: \n $SB"
adduser $user
usermod -aG sudo $user
echo  $user"   ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Check if pushover options were passed
if [[ -n $usrkey ]]; then
        printf "$ST Downloading and configuring Pushover notifications. \n $SB"

        #get main interface ip
        ip=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')

        #pushover notification options
        PO_USER_KEY=$usrkey
        PO_APP_KEY=$appkey
        PO_TITLE=$hostname
        PO_SOUND="gamelan"
        PO_URL="ssh://$ip:22"

        # download pushover script
        git clone https://rigslab.com/Rambo/Pushover.git
        chmod +x ./Pushover/install-pushover.sh
        ./Pushover/install-pushover.sh $PO_TITLE $PO_USER_KEY $PO_APP_KEY $PO_SOUND $PO_URL
        chmod +x /usr/bin/pushover
        rm -R ./Pushover

        printf "$ST Creating Login notification script \n $SB"
        touch /usr/bin/authee
        echo "#!/bin/bash" >> /usr/bin/authee
        echo "#Login Notification" >> /usr/bin/authee
        echo "MESSAGE=\"SSH Login: \`whoami\`\"" >> /usr/bin/authee
        echo "wget https://api.pushover.net/1/messages.json --post-data=\"token=$PO_APP_KEY&user=$PO_USER_KEY&message=\$MESSAGE&title=$PO_TITLE&url=$PO_URL&sound=$PO_SOUND\" -qO- > /dev/null 2>&1 &" >> /usr/bin/authee
        echo "#call a shell to open for the ssh session" >> /usr/bin/authee
        echo "#/bin/bash" >> /usr/bin/authee
        echo "#Subsystem sftp /usr/lib/openssh/sftp-server" >> /usr/bin/authee
        chmod +x /usr/bin/authee
        echo "#LOGIN NOTIFICATION SCRIPT" >> /home/$user/.bashrc
        echo "bash authee" >> /home/$user/.bashrc
fi


printf "$ST Securing SSH and Generating keys \n $SB"

#disable root login
sed -i -e 's/#PermitRootLogin\ prohibit-password/PermitRootLogin\ no/g' /etc/ssh/sshd_config # this covers proxmox cloud init defaults
sed -i -e 's/PermitRootLogin\ yes/PermitRootLogin\ no/g' /etc/ssh/sshd_config # this covers most vps' defaults

# disable password auth
sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication\ no/g' /etc/ssh/sshd_config 

#generate ssh keys
ssh-keygen
echo "$sshkey" >> /root/.ssh/authorized_keys

#copy keys to main user and set perms
mkdir /home/$user/.ssh
cp -R /root/.ssh/* /home/$user/.ssh/
chown -R $user:$user /home/$user/.ssh/
chmod 700 /home/$user/.ssh/
chmod 600 /home/$user/.ssh/authorized_keys
chmod 600 /home/$user/.ssh/id_rsa
chmod 644 /home/$user/.ssh/id_rsa.pub
service sshd restart

printf "$ST Setting hostname \n $SB"
hostnamectl set-hostname $hostname
hostname

printf "$ST Disabling ipv6 \n $SB"
sysctl -w net.ipv6.conf.all.disable_ipv6=1

printf "$ST Configuring and enabling Firewall \n $SB"
ufw allow 22/tcp
ufw enable

printf "$ST Configuring Tabby env variables \n $SB"
echo "#TABBY WORKING DIR SCRIPT" >> /home/$user/.bashrc
echo "export PS1=\"\$PS1\[\e]1337;CurrentDir=\"'/home/$user\a\]'" >> /home/$user/.bashrc
echo "Done."

# Check for panel option
case $panel in
    cloudpanel)
        printf "$ST Installing CloudPanel \n $SB" #only debian 11

        # Get main interface ip
        ip=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')

        # Add to hosts file
        echo "$ip $hostname" >> /etc/hosts

        # Install cloudpanel # update to be dynamic, breaks every update
        curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
        echo "2aefee646f988877a31198e0d84ed30e2ef7a454857b606608a1f0b8eb6ec6b6 install.sh" | \
        sha256sum -c && sudo bash install.sh

        # Get u
        user_ip=$(echo $SSH_CLIENT | awk '{print $1}')
        ufw allow from $user_ip to any port 8443
        ;;
    tinycp)
        printf "$ST Installing TinyCP \n $SB"

        # Define the character set for a password
        chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

        # Generate a random 10-character password
        password=$(openssl rand -base64 12 | tr -dc $chars | head -c 10)

        # Install tinycp
        apt install apt-transport-https dirmngr gnupg ca-certificates
        apt-key adv --fetch-keys http://repos.tinycp.com/debian/conf/gpg.key
        echo "deb http://repos.tinycp.com/debian all main" | sudo tee /etc/apt/sources.list.d/tinycp.list
        apt-get update && TINYCP_USER="$user" TINYCP_PASS=$password TINYCP_PORT="37337" apt-get install tinycp
        ;;
    webmin)
        printf "$ST Installing Webmin \n $SB"

        # Get latest version
        curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
        chmod +x /root/setup-repos.sh
        /root/setup-repos.sh
        apt-get install -y webmin --install-recommends

        # Grab the fixed openvpn module to install via ui
        wget https://github.com/a-schild/webmin-openvpn-debian-jessie/raw/master/openvpn.wbm.gz
        ;;
    openvpn)
        printf "$ST Installing OpenVPN \n $SB"
        
        git https://rigslab.com/Rambo/OpenVPN-Installer.git
        chmod +x ./OpenVPN-Installer/opv-installer.sh
        ./OpenVPN-Installer/opv-installer.sh 9070
        rm -R ./OpenVPN-Installer
        ;;
    steam)
        printf "$ST Installing Steam and Configuring system for game servers \n $SB"

        # Install steamcmd
        apt install lib32gcc-s1 software-properties-common -y
        dpkg --add-architecture i386
        add-apt-repository -U http://deb.debian.org/debian -c non-free-firmware -c non-free
        apt update && apt install steamcmd

        # Pre-req settings for ac game servers
        sysctl -w net.core.wmem_default=2000000
        sysctl -w net.core.rmem_default=2000000
        sysctl -w net.core.wmem_max=2000000
        sysctl -w net.core.rmem_max=2000000

        # Increase number of open files to prevent errors when running game servers
        echo "fs.file-max=100000" >> /etc/sysctl.conf && sysctl -p
        echo "* soft nofile 1000000" >> /etc/security/limits.conf
        echo "* hard nofile 1000000" >> /etc/security/limits.conf
        echo "session required pam_limits.so" >> /etc/pam.d/common-session
        ;;
    dockge)
        printf "$ST Installing Docker & Dockge \n $SB"

        # Install docker
        curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update && apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

        # Add user to docker group
        usermod -aG docker $user

        # Install dockge
        mkdir -p /opt/dockge /opt/stacks
        curl "https://dockge.kuma.pet/compose.yaml?port=5001&stacksPath=%2Fopt%2Fstacks" --output /opt/dockge/compose.yaml

        # Change port to only listen on 127.0.0.1. Will tunnel w/ cloudflare
        sed -i -e 's/-\ 5001:5001/-\ 127.0.0.1:5001:5001/g' /opt/dockge/compose.yaml

        # Start dockge
        docker compose -f /opt/dockge/compose.yaml up -d
        ;;
    *)
        echo "No panel chosen."
        ;;
esac

printf "$ST Server Setup Complete! \n$SB"
if [[ -n $usrkey ]]; then
  # Send notification if pushover installed
  pushover "Server Setup Complete" 
fi

# Show system info:
neofetch
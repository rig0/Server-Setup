#!/bin/bash
#RAMBO ARK SERVER SETUP [DEBIAN 9-12]

#Bash styling
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"
delay=2 # delay in seconds after showing step

printf "$ST Opening game ports \n $SB"
sleep $delay
#open ports for ark game server
sudo ufw allow 7777/udp
sudo ufw allow 27015/udp
sudo ufw allow 27020/udp 

printf "$ST Creating game folder \n $SB"
sleep $delay
mkdir ./Ark
steamcmd +force_install_dir ./Ark +login anonymous +app_update 376030 +quit

touch ./start_ark.sh
echo "#!/bin/bash" >> ./start_ark.sh
echo "./ShooterGame/Binaries/Linux/ShooterGameServer TheIsland?listen -server -log -NoBattlEye -webalarm -ActiveEvent=None -servergamelog" >> ./start_ark.sh

touch ./update_ark.sh
echo "#!/bin/bash" >> ./update_ark.sh
echo "steamcmd +force_install_dir ./Ark +login anonymous +app_update 376030 +quit" >> ./update_ark.sh

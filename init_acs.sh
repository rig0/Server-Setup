#!/bin/bash
#RAMBO ASSETTO CORSA SERVER SETUP [DEBIAN 9-11]

usr=$1 #username to create

#Bash styling
BLUE='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # no color
ST="\n${YELLOW}----------------------------------------------------------------------\n\n"
SB="\n----------------------------------------------------------------------\n\n${NC}"
delay=2 # delay in seconds after showing step

printf "$ST Installing GO compiler \n $SB"
sleep $delay
wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin
echo "#GO PATH" >> /home/$usr/.profile
echo "export PATH=$PATH:/usr/local/go/bin" >> /home/$usr/.profile
go version
go install github.com/mjibson/esc@latest

printf "$ST Installing NodeJS \n $SB"
sleep $delay
curl -fsSL https://deb.nodesource.com/setup_14.x | bash - 
apt install nodejs gcc g++ make -y
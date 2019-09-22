#!/bin/bash

#==========================================================================================
#get directory of script
#==========================================================================================
BASEDIR=$(dirname "$0")

#==========================================================================================
#prepare servers
#==========================================================================================
declare -a urls
declare -a users
declare -a passwords
filename="$BASEDIR/servers.txt"
n=0
echo "reading servers..."
while read urls[$n] && read users[$n] && read -r passwords[$n] ; do
    n=$((n+1))
done < $filename
serverscount=${#urls[@]}
echo "loaded $serverscount servers successfully!"

#==========================================================================================
#connect to server
#==========================================================================================
if (($1<0 || $1>$serverscount))
then
    echo "index is not correct!"
else
    echo "connecting to server $1 (${users[$1]}@${urls[$1]}) ..."
    sshpass -p "${passwords[$1]}" ssh  -o 'StrictHostKeyChecking no' -o ServerAliveInterval=180 -o ServerAliveCountMax=2 ${users[$1]}@${urls[$1]}
fi

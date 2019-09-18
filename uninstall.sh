#!/bin/bash

#unistall chain totally from servers
#usage: ./uinstall <chainname>

chainname=$1

echo "uninstalling chain: $chainnamefrom..."

#==========================================================================================
#prepare servers
#==========================================================================================
declare -a urls
declare -a users
declare -a passwords
filename='servers.txt'
n=0
echo "reading servers..."
while read urls[$n] && read users[$n] && read -r passwords[$n] ; do
    n=$((n+1))
done < $filename
serverscount=${#urls[@]}
echo "loaded $serverscount servers successfully!"

#==========================================================================================
#uninstalling process
#==========================================================================================
for ((i=0; i<$serverscount; i++)); do
    echo "uninstalling from server $i..."
    sshpass -p "${passwords[$i]}" ssh ${users[$i]}@${urls[$i]} "pkill -f burrow"
    sshpass -p "${passwords[$i]}" ssh ${users[$i]}@${urls[$i]} "rm -R $chainname"
done

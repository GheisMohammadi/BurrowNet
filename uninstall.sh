#!/bin/bash

#unistall chain totally from servers
#usage: ./uinstall.sh <chainname>

#==========================================================================================
#get full address of chain directory
#==========================================================================================
getChainDir()
{
    username=$1
    chainpath=""
    if [ $username=="root" ]; then
        chainpath="$chainname"
    else
        chainpath="/home/$username/$chainname"
    fi
}
#==========================================================================================

chainname=$1

if [ -z "$chainname" ]; then
    echo "please enter chain name:"
    read chainname
fi

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
    getChainDir "${users[$i]}"
    sshpass -p "${passwords[$i]}" ssh ${users[$i]}@${urls[$i]} "[ -d $chainpath ] && rm -R $chainpath"
done

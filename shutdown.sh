#!/bin/bash

#reset all nodes of chain
#usage: ./shutdown.sh <chainname>

#==========================================================================================
#get inputs from command line
#==========================================================================================
chainname=$1

if [ -z "$chainname" ]; then
    echo "please enter chain name:"
    read chainname
fi

echo "shutting down chain: $chainnamefrom..."

#==========================================================================================
#get directory of script
#==========================================================================================
BASEDIR=$(dirname "$0")

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

#==========================================================================================
#Check network status
#==========================================================================================
echo "=============================================="
echo "Shut down Nodes"
echo "=============================================="
for ((i=0; i<$serverscount; i++)); do
    echo "closing burrow in node $i ..."
    sshpass -p "${passwords[$i]}" ssh ${users[$i]}@${urls[$i]} "pkill -f burrow"
done

echo "=============================================="
echo "All nodes are turned off successfully!"
echo "Good Luck!"
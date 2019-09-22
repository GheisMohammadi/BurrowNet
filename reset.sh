#!/bin/bash

#reset all nodes of chain
#usage: ./reset.sh <chainname>

#==========================================================================================
#get inputs from command line
#==========================================================================================
chainname=$1

if [ -z "$chainname" ]; then
    echo "please enter chain name:"
    read chainname
fi

echo "reseting chain: $chainnamefrom..."

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
echo "Reset Nodes"
echo "=============================================="
for ((i=0; i<$serverscount; i++)); do
    echo "closing burrow in node $i ..."
    sshpass -p "${passwords[$i]}" ssh ${users[$i]}@${urls[$i]} "pkill -f burrow"
done

echo "waiting for confirm closing..."
sleep 5

echo "=============================================="
echo "Starting Nodes"
echo "=============================================="
for ((i=0; i<$serverscount; i++)); do
    echo "starting node $i ..."
    getChainDir "${users[$i]}"
    sshpass -p "${passwords[$i]}" ssh ${users[$i]}@${urls[$i]} "[ -e $chainpath/run_node.sh ] && | bash $chainpath/run_node.sh"
done
echo "=============================================="
echo "All nodes reset successfully!"
echo "Good Luck!"
#!/bin/bash

#Check network connected nodes
#usage: ./status.sh

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

#==========================================================================================
#Check network status
#==========================================================================================
for ((i=0; i<$serverscount; i++)); do
    echo "=============================================="
    echo "Connected Nodes"
    echo "=============================================="
    echo "from node $i:"
    curl -s ${users[1]}:20001/network | jq -r '.result.peers[].node_info.moniker'
done

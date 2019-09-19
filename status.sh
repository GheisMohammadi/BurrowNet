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
echo "=============================================="
echo "Connected Nodes"
echo "=============================================="
for ((i=1; i<$serverscount; i++)); do
    nNodes=`curl -s ${urls[$i]}:20001/network | jq -r '.result.n_peers'`
    if [ -z $nNodes ]; then
        nNodes="0"
    fi
    echo "[ $nNodes nodes are connected to node $i ]"
    curl -s ${urls[$i]}:20001/network | jq -r '.result.peers[].node_info.moniker'
    echo "=============================================="
done

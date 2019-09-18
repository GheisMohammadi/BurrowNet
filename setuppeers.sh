#!/bin/bash

chainname=$1
nodescount=$2

#prefixs for adding to address of peers
prefix1="tcp://" 
prefix2="tcp://"
prefix3=""

cd $chainname #burrow-testnet-2

echo "creating toml files for $nodescount peers..."
for i in `seq 1 $nodescount`
do
    echo "create toml file for validator $i ..."
    cp .burrow_init.toml .burrow_val$i.toml
done

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
#Find seed node external address
#==========================================================================================
echo "waiting for seed node url..."
SEED_URL=""
while [ -z $SEED_URL ]
do
    SEED_URL=`curl -s ${urls[0]}:10001/network | jq -r '.result.ThisNode | [.ID, .ListenAddress] | join("@") | ascii_downcase'`
    sleep 1
done

#remove tcp:// from SEED_URL (https://github.com/hyperledger/burrow/issues/1050)
SEED_URL=${SEED_URL//tcp:\/\//""}
#SEED_URL="tcp://$SEED_URL"

#print seed url
echo "seed url: $SEED_URL"

#==========================================================================================
#Configure other node to connect to seed node
#==========================================================================================
echo "updating toml files with seed url..."
for i in `seq 1 $nodescount`
do
    echo "upgrade seed address in toml file for validator $i ..."
    #make changes in seed config file
    sed -i s%"BurrowDir = \".burrow\""%"BurrowDir = \".burrow_node$i\""% .burrow_val$i.toml
    sed -i s%"Seeds = \"\""%"Seeds = \"${SEED_URL}\""% .burrow_val$i.toml
    sed -i s%"ListenHost = \"0.0.0.0\""%"ListenHost = \"$prefix1${urls[$i]}\""% .burrow_val$i.toml
    sed -i s%"ListenPort = \"26656\""%"ListenPort = \"20000\""% .burrow_val$i.toml
    sed -i s%"Moniker = \"\""%"Moniker = \"val_node_$i\""% .burrow_val$i.toml
    sed -i s%"GRPCServiceEnabled = true"%"GRPCServiceEnabled = false"% .burrow_val$i.toml
    sed -i s%"AllowBadFilePermissions = false"%"AllowBadFilePermissions = true"% .burrow_val$i.toml
    sed -i '/\[RPC.Info\]/,/BlockSampleSize = 100/d' .burrow_val$i.toml
    sed -i s%"\[RPC\]"%"\[RPC\] \n \[RPC.Info\] \n Enabled = true \n ListenHost = \"$prefix2${urls[$i]}\" \n ListenPort = \"20001\" \n \[RPC.Profiler\] \n Enabled = false \n \[RPC.GRPC\] \n Enabled = true \n ListenHost = \"$prefix3${urls[$i]}\" \n ListenPort = \"20002\" \n \[RPC.Metrics\] \n Enabled = false"% .burrow_val$i.toml
done

#==========================================================================================
#upload config files to peers
#==========================================================================================
echo "updloading toml files for $nodescount peers..."
for i in `seq 1 $nodescount`
do
    echo "cleaning files for validator $i (${users[$i]}@${urls[$i]})..."
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "[ -d $chainname/.keys ] && rm -R $chainname/.keys"
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "[ -d $chainname/.burrow_node$i ] && rm -R $chainname/.burrow_node$i"
    echo "uploading toml file for validator $i ..."
    sshpass -p "${passwords[$i]}" scp -o StrictHostKeyChecking=no ".burrow_val$i.toml" ${users[$i]}@${urls[$i]}:$chainname
    echo "uploading keys folder for validator $i ..."
    sshpass -p "${passwords[$i]}" scp -o StrictHostKeyChecking=no -r ".keys" ${users[$i]}@${urls[$i]}:$chainname
done

#==========================================================================================
#Start validator nodes
#==========================================================================================
echo "start validators..."
for i in `seq 1 $nodescount`
do
    echo "start validator $i ..."
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "bash $chainname/burrow start --validator=$i --config=.burrow_val$i.toml" &
done
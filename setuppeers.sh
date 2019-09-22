#!/bin/bash

#==========================================================================================
#read inputs from command line
#==========================================================================================
chainname="$1"
nodescount=$2
seeduser=$3
customip="$4"

#==========================================================================================
#constants
#==========================================================================================
#prefixs for adding to address of peers
prefix1="tcp://" 
prefix2="tcp://"
prefix3=""

#==========================================================================================
#get directory of script and go to directory
#==========================================================================================
BASEDIR=$(dirname "$0")
cd $BASEDIR

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
#create new screen for run in background
#==========================================================================================
#create new screen
#screen  

#==========================================================================================
#prepare servers
#==========================================================================================
declare -a urls
declare -a users
declare -a passwords
filename="servers.txt"
n=0
echo "reading servers..."
while read urls[$n] && read users[$n] && read -r passwords[$n] ; do
    n=$((n+1))
done < $filename
serverscount=${#urls[@]}
echo "loaded $serverscount servers successfully!"

#==========================================================================================
#wait for peer node
#==========================================================================================
#both setup seed and setup peers are running parallel then we need wait for seed first
until pids=$(pidof burrow)
do   
    sleep 1
done

#==========================================================================================
#prepare config files for validators
#==========================================================================================
echo "waiting for .burrow_init.toml ..."
while [ ! -e .burrow_init.toml ]
do
  sleep 1
done

echo "creating toml files for $nodescount peers..."
for i in `seq 1 $nodescount`
do
    echo "create toml file for validator $i ..."
    cp .burrow_init.toml .burrow_val$i.toml
    chmod 777 .burrow_val$i.toml
done

#==========================================================================================
#Find seed node external address
#==========================================================================================
echo "waiting for seed node url..."
SEED_URL=""
while [ -z $SEED_URL ]
do
    if [ -z $customip ]; then
        SEED_URL=`curl -s ${urls[0]}:20001/network | jq -r '.result.ThisNode | [.ID, .ListenAddress] | join("@") | ascii_downcase'`
    else
        SEED_URL=`curl -s $customip:20001/network | jq -r '.result.ThisNode | [.ID, .ListenAddress] | join("@") | ascii_downcase'`
    fi
    sleep 1
done

#remove tcp:// from SEED_URL (https://github.com/hyperledger/burrow/issues/1050)
SEED_URL=${SEED_URL//tcp:\/\//""}
SEED_URL=${SEED_URL//$customip/${urls[0]}}
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

    if [ -z $customip ]; then
    sed -i s%"ListenHost = \"0.0.0.0\""%"ListenHost = \"$prefix1${urls[$i]}\""% .burrow_val$i.toml
    else
    sed -i s%"ListenHost = \"0.0.0.0\""%"ListenHost = \"$customip\""% .burrow_val$i.toml
    sed -i s%"ExternalAddress = \"\""%"ExternalAddress = \"${urls[$i]}:20000\""% .burrow_val$i.toml
    fi
    sed -i s%"ListenPort = \"26656\""%"ListenPort = \"20000\""% .burrow_val$i.toml
    sed -i s%"Moniker = \"\""%"Moniker = \"val_node_$i\""% .burrow_val$i.toml
    sed -i s%"GRPCServiceEnabled = true"%"GRPCServiceEnabled = false"% .burrow_val$i.toml
    sed -i s%"AllowBadFilePermissions = false"%"AllowBadFilePermissions = true"% .burrow_val$i.toml
    sed -i '/\[RPC.Info\]/,/BlockSampleSize = 100/d' .burrow_val$i.toml
    if [ -z $customip ]; then
    sed -i s%"\[RPC\]"%"\[RPC\] \n \[RPC.Info\] \n Enabled = true \n ListenHost = \"$prefix2${urls[$i]}\" \n ListenPort = \"20001\" \n \[RPC.Profiler\] \n Enabled = false \n \[RPC.GRPC\] \n Enabled = true \n ListenHost = \"$prefix3${urls[$i]}\" \n ListenPort = \"20002\" \n \[RPC.Metrics\] \n Enabled = false"% .burrow_val$i.toml
    else
    sed -i s%"\[RPC\]"%"\[RPC\] \n \[RPC.Info\] \n Enabled = true \n ListenHost = \"$customip\" \n ListenPort = \"20001\" \n \[RPC.Profiler\] \n Enabled = false \n \[RPC.GRPC\] \n Enabled = true \n ListenHost = \"$customip\" \n ListenPort = \"20002\" \n \[RPC.Metrics\] \n Enabled = false"% .burrow_val$i.toml
    fi
done

#==========================================================================================
#upload config files to peers
#==========================================================================================
echo "updloading toml files for $nodescount peers..."
for i in `seq 1 $nodescount`
do
    getChainDir "${users[$i]}"
    echo "cleaning files for validator $i in address ${users[$i]}:${urls[$i]} ..."
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "[ -d $chainpath/.keys ] && rm -R $chainpath/.keys"
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "[ -d $chainpath/.burrow_node$i ] && rm -R $chainpath/.burrow_node$i"
    echo "uploading toml file for validator $i in address ${users[$i]}:${urls[$i]} ..."
    sshpass -p "${passwords[$i]}" scp -o StrictHostKeyChecking=no ".burrow_val$i.toml" ${users[$i]}@${urls[$i]}:$chainpath
    echo "uploading keys folder for validator $i in address ${users[$i]}:${urls[$i]} ..."
    sshpass -p "${passwords[$i]}" scp -o StrictHostKeyChecking=no -r ".keys" ${users[$i]}@${urls[$i]}:$chainpath
done

#==========================================================================================
#Start validator nodes
#==========================================================================================
echo "start validators..."
for i in `seq 1 $nodescount`
do
    getChainDir "${users[$i]}"
    echo "start validator $i ..."
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "echo \"    cd DOLLARSIGN(dirname DOLLARSIGN0)
    ./burrow start --validator=$i --config=.burrow_val$i.toml > peer_logs.log 2>&1 &\" > $chainpath/run_node.sh"
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "sed -i 's/DOLLARSIGN/$/g' $chainpath/run_node.sh"
    sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "chmod +x $chainpath/run_node.sh | bash $chainpath/run_node.sh" &

    #for run directly use this:
    #sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "bash $chainname/burrow start --validator=$i --config=.burrow_val$i.toml" &
done

echo "$nodescount nodes is running!"
echo "use ./status.sh for see connections!"

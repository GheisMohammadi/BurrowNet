#!/bin/bash

#==========================================================================================
#read inputs from command line
#==========================================================================================
chainname="$1"
validatorscount=$2
seedurl="$3"
seedusername="$4"
blockcreationtime="$5"
customip="$6"

#==========================================================================================
#get directory of script and go to directory
#==========================================================================================
BASEDIR=$(dirname "$0")
cd $BASEDIR

#==========================================================================================
#print input arguments
#==========================================================================================
echo "chain name: $chainname"
echo "validators count: $validatorscount"
echo "seed path: $seedusername@$seedurl"
echo "empty block creation time: $blockcreationtime"
echo "seed custome ip: $customip"

#==========================================================================================
#constants
#==========================================================================================
globalseedurl="0.0.0.0"
localseedurl="127.0.0.1"

prefix1="tcp://"
prefix2="" 

#==========================================================================================
#create new screen for run in background
#==========================================================================================
#create new screen
#screen 

#==========================================================================================
#Configure chain 
#==========================================================================================
#Generate keys for validator nodes
rm -rf .burrow* .keys*
./burrow spec --full-accounts=$validatorscount | ./burrow configure --chain-name=$chainname --keys-dir=.keys -s- > .burrow_init.toml

#Generate one additional key in another local store for seed node
./burrow spec -f1 | ./burrow configure --chain-name=$chainname --keys-dir=.keys_seed -s- > /dev/null

#change block creation time
sed -i s%"CreateEmptyBlocks = \"5m\""%"CreateEmptyBlocks = \"$blockcreationtime\""% .burrow_init.toml

#Seed node
cp .burrow_init.toml .burrow_seed.toml

#make changes in seed config file
sed -i s%"BurrowDir = \".burrow\""%"BurrowDir = \".burrow_seed_0\""% .burrow_seed.toml
sed -i s%"SeedMode = false"%"SeedMode = true"% .burrow_seed.toml
if [ -z $customip ]; then
sed -i s%"ListenHost = \"0.0.0.0\""%"ListenHost = \"$prefix1$seedurl\""% .burrow_seed.toml
else
sed -i s%"ListenHost = \"0.0.0.0\""%"ListenHost = \"$customip\""% .burrow_seed.toml
sed -i s%"ExternalAddress = \"\""%"ExternalAddress = \"$prefix1$seedurl:20000\""% .burrow_seed.toml
fi
sed -i s%"ListenPort = \"26656\""%"ListenPort = \"20000\""% .burrow_seed.toml
sed -i s%"Moniker = \"\""%"Moniker = \"seed_node_0\""% .burrow_seed.toml
sed -i s%"GRPCServiceEnabled = true"%"GRPCServiceEnabled = false"% .burrow_seed.toml
sed -i s%"AllowBadFilePermissions = false"%"AllowBadFilePermissions = true"% .burrow_seed.toml
sed -i s%"KeysDirectory = \".keys\""%"KeysDirectory = \".keys_seed\""% .burrow_seed.toml
sed -i '/\[RPC.Info\]/,/BlockSampleSize = 100/d' .burrow_seed.toml
if [ -z $customip ]; then
sed -i s%"\[RPC\]"%"\[RPC\] \n \[RPC.Info\] \n Enabled = true \n ListenHost = \"$prefix2$seedurl\" \n ListenPort = \"20001\" \n \[RPC.Profiler\] \n Enabled = false \n \[RPC.GRPC\] \n Enabled = false \n \[RPC.Metrics\] \n Enabled = false"% .burrow_seed.toml
else
sed -i s%"\[RPC\]"%"\[RPC\] \n \[RPC.Info\] \n Enabled = true \n ListenHost = \"$customip\" \n ListenPort = \"20001\" \n \[RPC.Profiler\] \n Enabled = false \n \[RPC.GRPC\] \n Enabled = false \n \[RPC.Metrics\] \n Enabled = false"% .burrow_seed.toml
fi

#==========================================================================================
#close current running burrow
#==========================================================================================
pid=`pgrep burrow`
if [ ! -z $pid ]; then
    echo "currently burrow instance with pid:$pid is running."
    echo "shutting down current running burrow ..."
    #kill burrow process
    pkill -f burrow;
    echo "waiting for shutting down..."
    while [ ! -z $pid ]; do
        sleep 1
        pid=`pgrep burrow`
    done
    echo "continue setup..."
fi

#==========================================================================================
#Create run node shell script for run seed node from other scripts
#==========================================================================================
dirstr="DOLLARSIGN(dirname DOLLARSIGN0)"
echo "cd $dirstr
./burrow start --address=`basename .keys_seed/data/* .json` --config=.burrow_seed.toml > seed_logs.log 2>&1 &" > "run_node.sh"
sed -i s%"DOLLARSIGN"%"\$"% run_node.sh
sed -i s%"DOLLARSIGN"%"\$"% run_node.sh
chmod +x "run_node.sh"

#==========================================================================================
#Start seed node
#==========================================================================================
echo "running seed node 0 ($seedurl) ..."
./burrow start --address=`basename .keys_seed/data/* .json` --config=.burrow_seed.toml > seed_logs.log 2>&1 &
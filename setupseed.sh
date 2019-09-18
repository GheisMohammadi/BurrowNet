#!/bin/bash

chainname=$1
validatorscount=$2
seedurl=$3
blockcreationtime=$4

seedurl1="0.0.0.0"
seedurl2="127.0.0.1"

prefix1="tcp://"
prefix2="" 

cd $chainname #burrow-testnet-2

#Configure chain
rm -rf .burrow* .keys*
./burrow spec --full-accounts=$validatorscount | ./burrow configure -s- > .burrow_init.toml

#Generate one additional key in another local store for seed node
./burrow spec -f1 | ./burrow configure --chain-name="$chainname" --keys-dir=.keys_seed -s- > /dev/null

#change block creation time
sed -i s%"CreateEmptyBlocks = \"5m\""%"CreateEmptyBlocks = \"$blockcreationtime\""% .burrow_init.toml

#Seed node
cp .burrow_init.toml .burrow_seed.toml

#make changes in seed config file
sed -i s%"BurrowDir = \".burrow\""%"BurrowDir = \".burrow_seed_0\""% .burrow_seed.toml
sed -i s%"SeedMode = false"%"SeedMode = true"% .burrow_seed.toml
sed -i s%"ListenHost = \"0.0.0.0\""%"ListenHost = \"$prefix1$seedurl\""% .burrow_seed.toml
sed -i s%"ListenPort = \"26656\""%"ListenPort = \"10000\""% .burrow_seed.toml
sed -i s%"Moniker = \"\""%"Moniker = \"seed_node_0\""% .burrow_seed.toml
sed -i s%"GRPCServiceEnabled = true"%"GRPCServiceEnabled = false"% .burrow_seed.toml
sed -i s%"AllowBadFilePermissions = false"%"AllowBadFilePermissions = true"% .burrow_seed.toml
sed -i s%"KeysDirectory = \".keys\""%"KeysDirectory = \".keys_seed\""% .burrow_seed.toml
sed -i '/\[RPC.Info\]/,/BlockSampleSize = 100/d' .burrow_seed.toml
sed -i s%"\[RPC\]"%"\[RPC\] \n \[RPC.Info\] \n Enabled = true \n ListenHost = \"$prefix2$seedurl\" \n ListenPort = \"10001\" \n \[RPC.Profiler\] \n Enabled = false \n \[RPC.GRPC\] \n Enabled = false \n \[RPC.Metrics\] \n Enabled = false"% .burrow_seed.toml

#Start the seed node
echo "running seed node 0 ..."
./burrow start --address=`basename .keys_seed/data/* .json` --config=.burrow_seed.toml

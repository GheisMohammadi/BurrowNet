#!/bin/bash

#istall new chain with given chain name and empty block creation time
#usage: ./install.sh <chainname> <creationtime>

#==========================================================================================
#prepare chain name
#==========================================================================================
chainname="$1"
now=$(date +"%Y%m%d")
if [ -z "$chainname" ]; then
    chainname="testnet_$now"
fi
echo "chain name: $chainname"

#==========================================================================================
#prepare creation time of empty blocks
#==========================================================================================
creationtime=$2
if [ -z "$creationtime" ]; then
    creationtime="0"
fi
echo "empty block creation time: $creationtime"

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
#print servers
#==========================================================================================
for ((i=0; i<$serverscount; i++)); do
        echo "${urls[$i]} --> user:${users[$i]} pass:${passwords[$i]}"
done

#==========================================================================================
#prepare testnet directory in servers and upload burrow executable file there 
#==========================================================================================
echo -n "create directory and upload burrow main file (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    for ((i=0; i<$serverscount; i++)); do
        echo "creating chain directory and upload burrow to server $i..."
        sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "mkdir -p $chainname"
        sshpass -p "${passwords[$i]}" scp -o StrictHostKeyChecking=no "burrow" ${users[$i]}@${urls[$i]}:$chainname
        sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "chmod 777 $chainname/burrow"
    done
else
    echo "continue installing..."
fi

#==========================================================================================
#upload shell files in seed node
#==========================================================================================
echo "upload shell files to server 0 (Seed Node)..."
sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "[ -e $chainname/setupseed.sh ] && rm $chainname/setupseed.sh | [ -e $chainname/setuppeers.sh ] && rm $chainname/setuppeers.sh | [ -e $chainname/servers.txt ] && rm $chainname/servers.txt"
sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "servers.txt" ${users[0]}@${urls[0]}:$chainname
sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "setupseed.sh" ${users[0]}@${urls[0]}:$chainname
sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "setuppeers.sh" ${users[0]}@${urls[0]}:$chainname

#==========================================================================================
#setup seed node
#==========================================================================================
echo "setup and run seed node ..."
sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "chmod 777 $chainname/burrow | chmod 777 $chainname/setupseed.sh | screen | bash $chainname/setupseed.sh $chainname $serverscount ${urls[0]} $creationtime" &

#==========================================================================================
#setup peers
#==========================================================================================
echo "setup peer nodes ..."
peerscount=$((serverscount-1))
sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "chmod 777 $chainname/setuppeers.sh | bash $chainname/setuppeers.sh $chainname $peerscount"
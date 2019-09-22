#!/bin/bash

#istall new chain with given chain name and empty block creation time
#usage: ./install.sh <chainname> <creationtime>

#==========================================================================================
#get directory of script
#==========================================================================================
BASEDIR=$(dirname "$0")

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
creationtime="$2"
if [ -z "$creationtime" ]; then
    creationtime="0"
fi
echo "empty block creation time: $creationtime"

#==========================================================================================
#check if need to run seed node with global ip 0.0.0.0
#==========================================================================================
customip="$3"
#remove tcp:// from custom ip
customip=${customip//tcp:\/\//""}

if [ ! -z "$customip" ]; then
    echo "custom IP address: $customip"
fi

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
echo "loaded $serverscount servers successfully!"

#==========================================================================================
#print servers
#==========================================================================================
for ((i=0; i<$serverscount; i++)); do
    if [ $i -gt 0 ]; then
    echo "node #$i: ${urls[$i]} --> user:${users[$i]} pass:${passwords[$i]}" 
    else
    echo "seed node: ${urls[$i]} --> user:${users[$i]} pass:${passwords[$i]}"
    fi
done

#==========================================================================================
#install dependencies in seed node
#==========================================================================================
echo -n "install deps in seed node (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    getChainDir "${users[0]}"
    echo "copy deps shell to seed server..."
    sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "[ ! -d $chainpath ] && mkdir -p $chainpath"
    sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "$BASEDIR/deps.sh" ${users[0]}@${urls[0]}:$chainpath
    #cmddepsandpass="sshpass -p \"${passwords[0]}\" ssh -o \'StrictHostKeyChecking no\' \"sudo bash $chainpath/deps.sh\"" 
    cmddeps="sudo bash $chainpath/deps.sh" 
    sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "chmod +x $chainpath/deps.sh | $cmddeps"
else
    echo "continue installing..."
fi

#==========================================================================================
#prepare testnet directory in servers and upload burrow executable file there 
#==========================================================================================
echo -n "install from the scratch (create new directory for chain and upload burrow executable file) (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    for ((i=0; i<$serverscount; i++)); do
        echo "creating chain directory and upload burrow to server $i..."
        getChainDir "${users[i]}"
        sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "[ ! -d $chainpath ] && mkdir -p $chainpath"
        sshpass -p "${passwords[$i]}" scp -o StrictHostKeyChecking=no "$BASEDIR/burrow" ${users[$i]}@${urls[$i]}:$chainpath
        sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "chmod +x $chainpath/burrow"
    done

    starttime=$(date +"%Y/%m/%d %T")

    echo "$chainname
start time: $starttime    
empty block creation time: $creationtime
custom IP address: $customip
seed node: ${users[0]}@${urls[0]}
servers count: $serverscount
chain path in servers: $chainpath" > "$BASEDIR/.chain.dat"

else
    echo "continue installing..."
fi

#==========================================================================================
#upload shell files in seed node
#==========================================================================================
echo "upload shell files to server 0 (Seed Node)..."
getChainDir "${users[0]}"
sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "[ -e $chainpath/setupseed.sh ] && rm $chainpath/setupseed.sh | [ -e $chainpath/setuppeers.sh ] && rm $chainpath/setuppeers.sh | [ -e $chainpath/servers.txt ] && rm $chainpath/servers.txt"
sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "$BASEDIR/servers.txt" ${users[0]}@${urls[0]}:$chainpath
sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "$BASEDIR/setupseed.sh" ${users[0]}@${urls[0]}:$chainpath
sshpass -p "${passwords[0]}" scp -o StrictHostKeyChecking=no "$BASEDIR/setuppeers.sh" ${users[0]}@${urls[0]}:$chainpath

#==========================================================================================
#setup seed node
#==========================================================================================
echo "setup and run seed node ..."
sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "chmod +x $chainpath/setupseed.sh | bash $chainpath/setupseed.sh \"$chainname\" $serverscount ${urls[0]} ${users[0]} \"$creationtime\" \"$customip\"" &

#==========================================================================================
#setup peers
#==========================================================================================
echo "setup peer nodes ..."
peerscount=$((serverscount-1))
sshpass -p "${passwords[0]}" ssh -o 'StrictHostKeyChecking no' ${users[0]}@${urls[0]} "chmod +x $chainpath/setuppeers.sh | bash $chainpath/setuppeers.sh $chainname $peerscount ${users[0]} \"$customip\"" &

#==========================================================================================
#wait for connections at least half of nodes
#==========================================================================================
sleep 20
echo "waiting for connections between nodes..."
npeers=`curl -s ${urls[1]}:20001/network | jq -r '.result.n_peers'`
connectednodes=$(expr $npeers + 0)
minconnections=$(expr $serverscount / 2 )
while [ $connectednodes -lt $minconnections ];
do
  sleep 1
  npeers=`curl -s ${urls[1]}:20001/network | jq -r '.result.n_peers'`
  connectednodes=$(expr $npeers + 0)
done

echo "minimum number of connections between nodes are detected."
echo "use command \"status\" for see connections!"
echo "Good luck!"
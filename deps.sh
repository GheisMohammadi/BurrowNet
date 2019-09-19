#!/bin/bash

#install all deps for seed node
#usage: ./deps.sh
#run this shell in seed node

#update
apt-get update

#install requirements
echo "install curl..."
apt-get -y install curl
echo "install sshpass..."
apt-get -y install sshpass
echo "install sed..."
apt-get -y install sed
echo "install jq..."
apt-get -y install jq
echo "install screen..."
apt-get -y install screen

#install screen on all nodes
#echo "install screen in nodes $i..."
#sshpass -p "${passwords[$i]}" ssh -o 'StrictHostKeyChecking no' ${users[$i]}@${urls[$i]} "apt-get -y install screen"

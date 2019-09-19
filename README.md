# BurrowNet
Create a test net or main net of hyperledger burrow using single command 

# Requirements
Make sure in the seed server the tools like curl,sshpass,sed,jq are installed. The shell script will install these requirements automatically but you can install them using commands below:

```bash
sudo apt-get update
sudo apt-get -y install curl
sudo apt-get -y install sshpass
sudo apt-get -y install sed
sudo apt-get -y install jq
```

and also make sure that there is no problem with port numbers 10001,10002,10003 for seed node and port numbers 20000,20001,20002 for validator nodes.

# Install burrow network
In this quick start, we will few create a small test net by 1 seed node and 3 validators

### Step1: Add your servers to servers.txt
open servers.txt and add url and user name and password of seed and validators instances to this file 
```bash
1.2.3.4
root
password1
6.22.87.91
root
password2
78.3.45.8
root
password3
23.79.33.58
root
password4
```

### Step2: Install network using install shell file
usage: install.sh [chainname] [empty_blocks_creation_time]

for example use line below for create a test net with name "testnet1" that creates an empty block every 5 minutes
```bash
sudo bash install.sh testnet1 5m
```
After installation, if everything goes well, the shell file automatically run all nodes and start commit blocks.

Your network is ready and you can send transaction or deploy smart contracts 

# Uninstall network 
usage: uninstall.sh [chainname]
```bash
sudo bash uninstall.sh testnet1
```

# Connect to node by ID number
usage: connect.sh [node_ID]

for example, for connect to node 1 use this:
```bash
sudo bash connect.sh 1
```

# Check Connected Nodes
usage: status.sh

for get current connected nodes to each node, use this command:
```bash
sudo bash status.sh
```
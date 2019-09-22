# BurrowNet
Create a test net or main net of hyperledger burrow using a single command 

# Requirements
First, provide one Linux server for seed node and N Linux servers for validator nodes. You can buy some instances in clouds like AWS, Alibaba, DigitalOcean or you can use your own dedicated servers or some old laptops with Linux as test net nodes.
Make sure in the seed server (first server in the list of servers) the tools like curl,sshpass,sed,jq,screen are installed. The shell script will install these requirements automatically but you can install them by executing commands below in seed server:

```bash
sudo apt-get update
sudo apt-get -y install curl
sudo apt-get -y install sshpass
sudo apt-get -y install sed
sudo apt-get -y install jq
sudo apt-get -y install screen
```

Make sure that you have access with ssh to all nodes on port 22 (ssh username@address). for example:
```bash
ssh myusername@1.2.3.4
```
If not, install ssh-openserver and enable ssh in all nodes. Don't forget forward port 22 in the router.

Check that all nodes have a strict and static IP address. If a node is getting IP from the router, forward port numbers 20000,20001,20002 to the local address of the node in the network (in case of using your laptops or physical servers by a router in the middle) and also make sure that there is no issue with port numbers 20000,20001,20002 for seed node and validator nodes. Some common issues are mismatch or wrong address in IP tables or hosts configuration or banned port by firewalls.
For ease of use, you can disable Firewall at beginning using:
```bash
sudo ufw disable
```
or just allow port numbers in firewall using:
```bash
sudo ufw allow 22/tcp
sudo ufw allow 20000:20002/tcp
```

# Install burrow network
In this quick start, we will few create a small test net by 1 seed node and 3 validators

### Step1: Add your servers to servers.txt
Open servers.txt and add "url" and "user name" and "password" of seed and validators instances in this file. 
Use "public IP Address" in case of using nodes in different local networks with the router in the middle. First in the list is considered as seed node and rests will be full validators. 

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
usage: install.sh [chainname] [empty_blocks_creation_time] [custom_ip]

for example use line below for creating a test net with name "testnet1" in cloud servers that creates an empty block every 5 minutes. 
```bash
sudo bash install.sh testnet1 "5m"
```

and use the command below for creating a test net with the name "testnet1" in your physical servers with routers in middle (can also use your old linux laptops) that creates an empty block every 5 minutes. 
```bash
sudo bash install.sh testnet1 "5m" "0.0.0.0"
```

Scripts will ask you about the installation of dependencies that if already installed just answer "n". Next question would be about install network from scratch that safe answer is "y".
After installation, if everything goes well, the shell script will run automatically all nodes and starts committing blocks.

Your network is ready to go and you can send transaction or deploy smart contracts as well. 
use "http://NodeIP:20001" to see APIs. 

# Check Connected Nodes
usage: status.sh

for checking current connected nodes to each node, use this command:
```bash
sudo bash status.sh
```

# Uninstall network 
usage: uninstall.sh [chainname]
```bash
sudo bash uninstall.sh testnet1
```

# Shutdown network 
usage: shutdown.sh [chainname]
turn off all nodes.

```bash
sudo bash shutdown.sh testnet1
```

# Reset network 
usage: reset.sh [chainname]
restart all nodes.

```bash
sudo bash reset.sh testnet1
```

# Connect to node by ID number
usage: connect.sh [node_ID]

for example, for connecting to node 1 use this:
```bash
sudo bash connect.sh 1
```
bash script will add node to known hosts list if it is not and will create connectiom and keep it alive.

#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error occurred in command $1. Exiting..."
    exit 1
}

# Command 1
echo "Executing Command 1..."
bash -c "$(wget -qO- https://raw.githubusercontent.com/dmitio/script/main/root.sh)"
if [ $? -ne 0 ]; then
    handle_error 1
fi

# Command 2
echo "Executing Command 2..."
apt-get update
if [ $? -ne 0 ]; then
    handle_error 2
fi

# Command 3
echo "Executing Command 3..."
apt-get update -y && apt-get install curl -y
if [ $? -ne 0 ]; then
    handle_error 3
fi

# Command 4
echo "Executing Command 4..."
apt-get install sudo
if [ $? -ne 0 ]; then
    handle_error 4
fi

# Command 5
echo "Executing Command 5..."
wget -qO- get.docker.com | bash
if [ $? -ne 0 ]; then
    handle_error 5
fi

# Command 6
echo "Executing Command 6..."
systemctl enable docker
if [ $? -ne 0 ]; then
    handle_error 6
fi

# Command 7
echo "Executing Command 7..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
if [ $? -ne 0 ]; then
    handle_error 7
fi

# Command 8
echo "Executing Command 8..."
sudo chmod +x /usr/local/bin/docker-compose
if [ $? -ne 0 ]; then
    handle_error 8
fi

echo "All commands executed successfully."
exit 0

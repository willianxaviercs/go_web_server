#!/bin/bash

my_dir=$(dirname $0)
checkpoint=$(cat $my_dir/setup_checkpoint || echo 0)

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit 1
fi

function save_checkpoint()
{
    echo $1 > $my_dir/setup_checkpoint
}

# update SO and install utilities
if [ $checkpoint -lt 10 ]; then
    dnf update -y
    save_checkpoint 10
fi

# install Go
if [ $checkpoint -lt 20 ]; then
    dnf install golang -y
    save_checkpoint 20
fi

# install service
if [ $checkpoint -lt 30 ]; then
    cp $my_dir/http_server.service /etc/systemd/system/http_server.service
    chmod 644 /etc/systemd/system/http_server.service
    systemctl enable http_server
fi

BLUE=$'\e[1;34m'
RESET=$'\e[0m'

cat <<HELP
Setup complete!
${BLUE}Edit the config file:${RESET}
        vim ./src/config/config.go
${BLUE}Deploy the server:${RESET}
        ./server/deploy.sh
HELP
#!/bin/bash

checkpoint=$(cat $my_dir/setup_checkpoint || echo 0)

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit 1
fi

function save_checkpoint()
{
    echo $1 > ./setup_checkpoint
}

function do_as_user()
{
    sudo -u $1 --preserve-env=PATH bash -s 
}

# Create users
if [ $checkpoint -lt 5 ]; then
    # web administrator
    groupadd webadm
    useradd webadm -G wheel

    save_checkpoint 5
fi

# update SO and install utilities
1if [ $checkpoint -lt 10 ]; then

    # update SO
    dnf update -y

    # install utilities
    dnf install vim git make -y

    save_checkpoint 10
fi

# install Go
if [ $checkpoint -lt 20 ]; then
    dnf install golang -y

    save_checkpoint 20
fi



# Configure git
if [ $checkpoint -lt 25 ]; then
    set +x
    do_as_user webadm <<'SCRIPT'
        ssh-keygen -C "dev-server" -f ~/.ssh/github-web-server-rsa
        git config --global core.sshCommand "ssh -i ~/.ssh/github-web-server-rsa
SCRIPT
    echo "Add the key to the project"
    echo ""
    cat /home/webadm/.ssh/github-web-server-rsa.pub
    echo ""
    echo "Run this script again after you're done"
    save_checkpoint 25
    exit 0
fi


# Clone repo
if [ $checkpoint -lt 30 ]; then
    do_as_user webadm <<'SCRIPT'
        set -euxo pipefail
        cd ~
        git clone git@github.com:willianxaviercs/go_web_server.git
SCRIPT
    save_checkpoint 30
fi

# install services
if [ $checkpoint -lt 40 ]; then
    # web server service
    cp home/webadm/http_server/server/http_server.service /etc/systemd/system/http_server.service
    chmod 644 /etc/systemd/system/http_server.service
    systemctl enable http_server

    save_checkpoint 40
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
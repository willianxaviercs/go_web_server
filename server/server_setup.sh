#!/bin/bash

BLUE=$'\e[1;34m'
RESET=$'\e[0m'
ORANGE=$'\e[38;2;234;138;4m'

checkpoint=$(cat ./setup_checkpoint || echo 0)
adm_name='devops'
project_remote='git@github.com:willianxaviercs/go_web_server.git'
project_folder='http_server'

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
if [ $checkpoint -lt 10 ]; then

    # web administrator
    groupadd --system $adm_name
    useradd --system \
        --gid $adm_name \
        --shell /bin/bash \
        --create-home --home-dir /home/$adm_name \
        $adm_name

    save_checkpoint 10
fi

# update SO and install utilities
if [ $checkpoint -lt 20 ]; then

    # update SO
    dnf update -y

    # install utilities
    dnf -y install 'vim' 'git' 'make'

    save_checkpoint 20
fi

# install Go
if [ $checkpoint -lt 30 ]; then
    dnf -y install golang

    save_checkpoint 30
fi

# Configure git
if [ $checkpoint -lt 40 ]; then
    #set +x
    do_as_user $adm_name <<'SCRIPT'
        ssh-keygen -C "dev-server" -f ~/.ssh/github-web-server-rsa
        git config --global core.sshCommand "ssh -i ~/.ssh/github-web-server-rsa"
SCRIPT

    printf "${ORANGE}1 - Copy the following key:${RESET}\n"
    echo ""
    cat /home/${adm_name}/.ssh/github-web-server-rsa.pub
    echo ""
    printf "${ORANGE}2 - Add it as a Deploy Key to your project${RESET}\n"
    echo ""
    echo "${ORANGE}3 - Run this script again after you're done${RESET}\n"

    save_checkpoint 40
    exit 0
fi

# NOTE: if you use something other than github, this section might fail
# Configure git
if [ $checkpoint -lt 50 ]; then
    do_as_user $adm_name <<SCRIPT
        set -euo pipefail
        ssh -T -i ~/.ssh/github-web-server-rsa git@github.com
SCRIPT
    if [ $? -eq 255 ]; then
        printf "${ORANGE}1 - Copy the following key:${RESET}\n"
        echo ""
        cat /home/${adm_name}/.ssh/github-web-server-rsa.pub
        echo ""
        printf "${ORANGE}2 - Add it as a Deploy Key to your project${RESET}\n"
        echo ""
        echo "${ORANGE}3 - Run this script again after you're done${RESET}"
        exit 255
    fi
    save_checkpoint 50
fi

# Clone repo
if [ $checkpoint -lt 60 ]; then
    do_as_user $adm_name <<SCRIPT
        set -euxo pipefail
        cd ~
        git clone $project_remote $project_folder
SCRIPT
    save_checkpoint 60
fi

# install services
if [ $checkpoint -lt 80 ]; then
    cp /home/${adm_name}/http_server/server/http_server.service /etc/systemd/system/http_server.service
    chmod 644 /etc/systemd/system/http_server.service
    systemctl enable http_server

    save_checkpoint 80
fi

cat <<HELP
Setup complete!
${ORANGE}Edit the config file:${RESET}
        vim ./src/config/config.go
${ORANGE}Edit the service file:${RESET}
        vim /etc/systemd/system/http_server.service
${ORANGE}Deploy the server:${RESET}
        ./server/deploy.sh
HELP
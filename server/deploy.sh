#!/bin/bash

BLUE_BOLD='\e[1;34m'
RESET='\e[0m'

set -eo pipefail

do_as() {
    sudo -u $1 --preserve-env=PATH bash -s
}

branch=$1
if [ -z "$branch" ]; then
        echo "Type the name of the branch you would like to deploy: "
        read branch
fi

echo "Deploying branch ${BLUE}$branch${RESET}..."

echo "Stoping service"
systemctl stop http_server

do_as devops <<SCRIPT
    set -euo pipefail
    cd /home/devops/http_server
    git fetch --all
    git reset --hard origin/$branch
SCRIPT

echo "Building binary"

do_as devops <<SCRIPT
    set -euo pipefail
    cd /home/devops/http_server/
    mkdir -p bin
    go build -o ./bin/http_server ./src/main.go
SCRIPT

echo "Starting service"
systemctl daemon-reload
systemctl start http_server
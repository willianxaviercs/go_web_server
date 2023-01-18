#!/bin/bash

# INFO: Deployment steps
#       1 - Stop what needs to be stopped (services, app, etc)
#       2 - Fetch branch to be deployed
#       3 - Apply database migrations
#       4 - Start what was stopped
#       5 - (Optional) - discord webhook info about the deploy

ORANGE=$'\e[38;2;234;138;4m'
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

echo -e "Deploying branch ${ORANGE}$branch${RESET}..."

systemctl stop http_server

do_as devops <<SCRIPT
    set -euo pipefail
    cd /home/devops/http_server
    git fetch --all
    git reset --hard origin/$branch
SCRIPT

do_as devops <<SCRIPT
    set -euo pipefail
    cd /home/devops/http_server/
    mkdir -p bin
    go build -o ./bin/http_server ./src/main.go
SCRIPT

systemctl daemon-reload
systemctl start http_server

echo "Finished!"

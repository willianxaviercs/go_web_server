#!/bin/bash

BLUE_BOLD=$'\e[1;34m'
RESET=$'\e[0m'
my_dir=$(dirname $0)

set -eo pipefail

branch=$1
if [ -z "$branch" ]; then
        echo "Type the name of the branch you would like to deploy: "
        read branch
fi

echo "Deploying branch ${BLUE}$branch${RESET}..."

echo "Stoping service"
systemctl stop http_server

git fetch --all
git reset --hard origin/$branch
<<SCRIPT
set -euo pipefail
SCRIPT

echo "Building binary"
mkdir -p $my_dir/../bin
go build -o $my_dir/../bin/http_server $my_dir/../src/main.go


echo "Starting service"
systemctl start http_server
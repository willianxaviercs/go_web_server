#!/bin/bash

my_dir=$(dirname $0)

set -eo pipefail

echo "Stoping service"
systemctl stop http_server

echo "Building binary"
mkdir -p $my_dir/../bin
go build -o $my_dir/../bin/http_server $my_dir/../src/main.go


echo "Starting service"
systemctl start http_server
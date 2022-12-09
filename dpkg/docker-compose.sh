#!/usr/bin/env bash

sudo apt install -y curl wget

VERSION="1.29.2"

wget "https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-Linux-x86_64"

chmod +x docker-compose-Linux-x86_64 && \
sudo mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose

sudo usermod -aG docker $USER
newgrp docker

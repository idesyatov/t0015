#!/usr/bin/env bash

# DOCKER UBUNTU

sudo apt-get update && \
sudo apt install curl software-properties-common ca-certificates apt-transport-https -y && \
sudo mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable"| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
sudo apt update && sudo apt upgrade -y && \
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin net-tools -y

sudo usermod -aG docker $USER
newgrp docker

#!/usr/bin/env bash

# Taken from https://docs.docker.com/engine/install/ubuntu/
set -x

if is os name ne linux; then
    echo "Linux only"
    exit 1
fi

sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Verify the Docker GPG key fingerprint
DOCKER_GPG_FINGERPRINT="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"
if ! gpg --no-default-keyring --keyring /etc/apt/keyrings/docker.gpg --list-keys "$DOCKER_GPG_FINGERPRINT" &>/dev/null; then
    echo "ERROR: Docker GPG key fingerprint verification failed!"
    sudo rm -f /etc/apt/keyrings/docker.gpg
    exit 1
fi

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo docker run hello-world

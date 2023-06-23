#!/bin/bash

docker run \
    --rm \
    -it \
    -p 8000:8000 \
    --volume "$PWD:/sandbox" \
    -v "$HOME/dot-files/bashrc-docker:/root/.bashrc" \
    -v "$HOME/dot-files/docker-utils:/root/docker-utils" \
    arm64v8/php \
    bash -c "./root/docker-utils/install-composer.sh && cd /sandbox && composer install && php -S 0.0.0.0:8000"

#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

NODE_MODULES='bash-language-server fkill-cli'

if [[ $(command -v yarnx -v) ]]; then
    echo "yarn already installed"
else
    rm -rf $HOME/.yarn
    curl -o- -L https://yarnpkg.com/install.sh | bash
fi

if [ $IS_MM = false ]; then
    yarn global add $NODE_MODULES || true
else
    yarn add $NODE_MODULES || true
fi

if [ $IS_DARWIN = true ]; then
    yarn global add alfred-fkill || true
fi

exit 0

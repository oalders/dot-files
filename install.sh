#!/usr/bin/env bash

set -eu -o pipefail

skip_vim_plugin_install=false

# https://stackoverflow.com/questions/16483119/example-of-how-to-use-getopts-in-bash
usage() {
    echo "Usage: $0 [-s] " 1>&2
    exit 1
}

while getopts ":s" o; do
    case "${o}" in
    s)
        skip_vim_plugin_install=true
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

LINK_FLAG=""

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    echo "This is Darwin"
    LINK_FLAG="-hF"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "This is Linux"
    LINK_FLAG="-T"
fi

echo $SELF_PATH

mkdir -p ~/.cpanreporter
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d
mkdir -p ~/.npm-packages
mkdir -p ~/.ssh/sockets

IS_MM=false
if [ -e /usr/local/bin/mm-perl ]; then
    IS_MM=true
fi

ln -sf $SELF_PATH/ackrc ~/.ackrc
ln -sf $SELF_PATH/bashrc ~/.bashrc
ln -sf $SELF_PATH/bash_profile ~/.bash_profile
ln -sf $SELF_PATH/cpanreporter/config.ini ~/.cpanreporter/config.ini
cp $SELF_PATH/dataprinter ~/.dataprinter # Data::Printer doesn't like symlinks
chmod 700 ~/.dataprinter

ln -sf $SELF_PATH/digrc ~/.digrc
ln -sf $LINK_FLAG $SELF_PATH/dzil ~/.dzil
ln -sf $SELF_PATH/gitignore_global ~/.gitignore_global
ln -sf $SELF_PATH/minicpanrc ~/.minicpanrc
if [ $IS_MM = false ]; then
    ln -sf $SELF_PATH/npmrc ~/.npmrc
fi
ln -sf $SELF_PATH/perlcriticrc ~/.perlcriticrc
ln -sf $SELF_PATH/perltidyrc ~/.perltidyrc
ln -sf $SELF_PATH/profile ~/.profile
ln -sf $SELF_PATH/proverc ~/.proverc
ln -sf $SELF_PATH/psqlrc ~/.psqlrc
ln -sf $SELF_PATH/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $SELF_PATH/screenrc ~/.screenrc
ln -sf $SELF_PATH/ssh/rc ~/.ssh/rc
ln -sf $LINK_FLAG $SELF_PATH/sqitch ~/.sqitch
ln -sf $SELF_PATH/tigrc ~/.tigrc
ln -sf $SELF_PATH/tmux.conf ~/.tmux.conf
ln -sf $SELF_PATH/tmux/macos ~/.tmux-macos
ln -sf $SELF_PATH/tmux/linux ~/.tmux-linux
ln -sf $SELF_PATH/Vagrantfile ~/.vagrant.d/Vagrantfile
ln -sf $SELF_PATH/vim/vimrc ~/.vimrc

mkdir -p ~/.vim
ln -sf $LINK_FLAG $SELF_PATH/vim/after ~/.vim/after
ln -sf $LINK_FLAG $SELF_PATH/vim/ftplugin ~/.vim/ftplugin

git submodule init
git submodule update

./git-config.sh

if [ $IS_MM = true ]; then
    ln -sf ~/mm-dot-files/maxmind_local_vimrc ~/.local_vimrc
    git config --global --unset-all remote.origin.fetch
else
    ln -sf $SELF_PATH/vim/vanilla_local_vimrc ~/.local_vimrc
    ln -sf $SELF_PATH/ssh/config ~/.ssh/config
fi

#go get github.com/github/hub

if [ -n "${GOPATH+set}" ] && [$(type "go" >/dev/null) ]; then
    echo "Installing shfmt"
    go get -u mvdan.cc/sh/cmd/shfmt

    echo "Installing golangci-lint"
    go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
fi

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

if [ $(which pip) ]; then
    pip install --user --upgrade pip
else
    which apt-get && sudo apt-get install -y python-pip
fi

./install-fpp.sh

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    pushd $LOCALCHECKOUT
    git pull origin master
    popd
fi

npm install npm acorn

NODE_MODULES='bash-language-server eslint fkill-cli jsonlint prettier'

if [ $IS_MM = false ]; then
    npm install --global $NODE_MODULES || true
else
    npm install $NODE_MODULES || true
fi

# pynvim is for vim-hug-neovim-rpc
pip install --user vint yamllint pynvim

# vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

rm -rf ~/.vim/Trashed-Bundles ~/.vim/bundle

if [ "$skip_vim_plugin_install" = true ]; then
    echo "Skip vim plug install.  Is this run via ansible?"
else
    vim -c ':PlugInstall'
fi

if [ $IS_MM = false ]; then
    cpanm App::cpm
    cpm install -g --cpanfile cpan/development.cpanfile
fi

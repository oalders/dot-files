#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

# https://stackoverflow.com/a/17072017/406224
if [ $IS_DARWIN = true ]; then
    brew config
    brew update
    brew bundle install --file=brew/macos-Brewfile

    # These packages are installed because they are needed for the Linux tests.
    # It's not clear how to have them not be installed for MacOS on Travis
    if [[ $USER != 'travis' ]]; then
        brew bundle install --file=brew/macos-skip-on-travis-Brewfile
    fi
fi

mkdir -p ~/.cpanreporter
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d
mkdir -p ~/.npm-packages
mkdir -p ~/.ssh/sockets

SELF_PATH=$(self_path)

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
ln -sf $SELF_PATH/Vagrantfile ~/.vagrant.d/Vagrantfile

git submodule init
git submodule update

./git-config.sh

if [ $IS_MM = true ]; then
    git config --global --unset-all remote.origin.fetch
fi

if [ $IS_DARWIN = true ]; then
    ln -sf $SELF_PATH/ssh/config ~/.ssh/config
else
    rm -f ~/.ssh/config
    ln -sf $SELF_PATH/ssh/no-include-config ~/.ssh/config
fi


#go get github.com/github/hub

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

# deps for vim and fpp
./pip.sh

./configure-vim.sh

./install-fpp.sh

./configure-tmux.sh

NODE_MODULES='bash-language-server fkill-cli'

if [ $IS_MM = false ]; then
    yarn global add $NODE_MODULES || true
else
    yarn add $NODE_MODULES || true
fi

if [ $IS_MM = false ]; then
    cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    cpanm --notest App::cpm
    if [ $(which plenv) ]; then
        plenv rehash
    fi
    cpm install -g --cpanfile cpan/development.cpanfile
    if [ $(which plenv) ]; then
        plenv rehash
    fi
fi

if [ $IS_DARWIN = false ]; then
    ./install-linux.sh
fi

exit 0

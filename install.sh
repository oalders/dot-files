#!/usr/bin/env bash

SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

echo $SELF_PATH

ln -sf $SELF_PATH/ackrc ~/.ackrc
ln -sf $SELF_PATH/bashrc ~/.bashrc
ln -sf $SELF_PATH/minicpanrc ~/.minicpanrc
ln -sf $SELF_PATH/perlcriticrc ~/.perlcriticrc
ln -sf $SELF_PATH/perltidyrc ~/.perltidyrc
ln -sf $SELF_PATH/screenrc ~/.screenrc
ln -sf $SELF_PATH/vim/vimrc ~/.vimrc

git submodule init
git submodule update

$SELF_PATH/inc/vim-update-bundles/vim-update-bundles

sh git_config.sh

curl -L http://cpanmin.us | perl - --self-upgrade
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

# git extras
echo "installing git-extras"

cd inc/git-extras
sudo make install PREFIX="~/local"

# for some reason a "~" folder gets created in the git-extras install
sudo git clean -df

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

#exec $SHELL

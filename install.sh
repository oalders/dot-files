#!/usr/bin/env bash

set -eu -o pipefail
SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

echo $SELF_PATH

mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d

ln -sf $SELF_PATH/ackrc ~/.ackrc
ln -sf $SELF_PATH/bashrc ~/.bashrc
ln -sf $SELF_PATH/bash_profile ~/.bash_profile
cp     $SELF_PATH/dataprinter ~/.dataprinter # Data::Printer doesn't like symlinks
chmod 700 ~/.dataprinter

ln -sfT $SELF_PATH/dzil ~/.dzil
ln -sf $SELF_PATH/minicpanrc ~/.minicpanrc
ln -sf $SELF_PATH/perlcriticrc ~/.perlcriticrc
ln -sf $SELF_PATH/perltidyrc ~/.perltidyrc
ln -sf $SELF_PATH/profile ~/.profile
ln -sf $SELF_PATH/proverc ~/.proverc
ln -sf $SELF_PATH/psqlrc ~/.psqlrc
ln -sf $SELF_PATH/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $SELF_PATH/screenrc ~/.screenrc
ln -sfT $SELF_PATH/sqitch ~/.sqitch
ln -sf $SELF_PATH/tmux.conf ~/.tmux.conf
ln -sf $SELF_PATH/tmux/macos ~/.tmux-macos
ln -sf $SELF_PATH/tmux/linux ~/.tmux-linux
ln -sf $SELF_PATH/Vagrantfile ~/.vagrant.d/Vagrantfile
ln -sf $SELF_PATH/vim/vimrc ~/.vimrc

mkdir -p ~/.vim
ln -sfT $SELF_PATH/vim/after ~/.vim/after

if [ -f /usr/local/bin/mm-perl ]
then
    ln -sf $SELF_PATH/vim/maxmind_local_vimrc ~/.local_vimrc
else
    ln -sf $SELF_PATH/vim/vanilla_local_vimrc ~/.local_vimrc
fi

git submodule init
git submodule update

$SELF_PATH/inc/vim-update-bundles/vim-update-bundles

./git-config.sh

#go get github.com/github/hub

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

./install-fpp.sh

LOCALCHECKOUT=~/.tmux/plugins/tpm
if [ ! -d $LOCALCHECKOUT ]
then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    pushd $LOCALCHECKOUT
    git pull origin master
    popd
fi

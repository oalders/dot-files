#!/usr/bin/env bash

SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

echo $SELF_PATH

mkdir -p ~/.re.pl

ln -sf $SELF_PATH/ackrc ~/.ackrc
ln -sf $SELF_PATH/bashrc ~/.bashrc
ln -sf $SELF_PATH/bash_profile ~/.bash_profile
cp     $SELF_PATH/dataprinter ~/.dataprinter # Data::Printer doesn't like symlinks
chmod 700 ~/.dataprinter

ln -sf $SELF_PATH/dzil ~/.dzil
ln -sf $SELF_PATH/minicpanrc ~/.minicpanrc
ln -sf $SELF_PATH/perlcriticrc ~/.perlcriticrc
ln -sf $SELF_PATH/perltidyrc ~/.perltidyrc
ln -sf $SELF_PATH/profile ~/.profile
ln -sf $SELF_PATH/proverc ~/.proverc
ln -sf $SELF_PATH/psqlrc ~/.psqlrc
ln -sf $SELF_PATH/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $SELF_PATH/screenrc ~/.screenrc
ln -sf $SELF_PATH/sqitch ~/.sqitch
ln -sf $SELF_PATH/tmux.conf ~/.tmux.conf
ln -sf $SELF_PATH/vim/vimrc ~/.vimrc
ln -sf $SELF_PATH/vim/after ~/.vim/after

# clean up recursive links
rm vim/after/after
rm dzil/dzil

git submodule init
git submodule update

$SELF_PATH/inc/vim-update-bundles/vim-update-bundles

sh git_config.sh

go get github.com/github/hub

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

# git extras
echo "installing git-extras"

cd inc/git-extras
make install PREFIX="~/local"

# for some reason a "~" folder gets created in the git-extras install
sudo git clean -df

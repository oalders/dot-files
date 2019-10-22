#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

mkdir -p ~/.cpanreporter
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d
mkdir -p ~/.npm-packages

DOT_FILES="~/dot-files"

ln -sf $DOT_FILES/ackrc ~/.ackrc
ln -sf $DOT_FILES/bashrc ~/.bashrc
ln -sf $DOT_FILES/bash_profile ~/.bash_profile
ln -sf $DOT_FILES/cpanreporter/config.ini ~/.cpanreporter/config.ini
cp $DOT_FILES/dataprinter ~/.dataprinter # Data::Printer doesn't like symlinks
chmod 700 ~/.dataprinter

ln -sf $DOT_FILES/digrc ~/.digrc
ln -sf $LINK_FLAG $DOT_FILES/dzil ~/.dzil
ln -sf $DOT_FILES/gitignore_global ~/.gitignore_global
ln -sf $DOT_FILES/minicpanrc ~/.minicpanrc
if [ $IS_MM = false ]; then
    ln -sf $DOT_FILES/npmrc ~/.npmrc
fi
ln -sf $DOT_FILES/perlcriticrc ~/.perlcriticrc
ln -sf $DOT_FILES/perltidyrc ~/.perltidyrc
ln -sf $DOT_FILES/profile ~/.profile
ln -sf $DOT_FILES/proverc ~/.proverc
ln -sf $DOT_FILES/psqlrc ~/.psqlrc
ln -sf $DOT_FILES/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf $DOT_FILES/screenrc ~/.screenrc
ln -sf $LINK_FLAG $DOT_FILES/sqitch ~/.sqitch
ln -sf $DOT_FILES/tigrc ~/.tigrc
ln -sf $DOT_FILES/Vagrantfile ~/.vagrant.d/Vagrantfile

exit 0

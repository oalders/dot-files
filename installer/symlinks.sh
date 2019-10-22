#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

mkdir -p ~/.cpanreporter
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d
mkdir -p ~/.npm-packages

SELF_PATH = "${SELF_PATH}/.."
echo "self path is $SELF_PATH"

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
ln -sf $LINK_FLAG $SELF_PATH/sqitch ~/.sqitch
ln -sf $SELF_PATH/tigrc ~/.tigrc
ln -sf $SELF_PATH/Vagrantfile ~/.vagrant.d/Vagrantfile

exit 0

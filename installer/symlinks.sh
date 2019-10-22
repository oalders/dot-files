#!/usr/bin/env bash

set -eu -o pipefail

pushd ~/dot-files
source bash_functions.sh

mkdir -p ~/.cpanreporter
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d
mkdir -p ~/.npm-packages

ln -sf ackrc ~/.ackrc
ln -sf bashrc ~/.bashrc
ln -sf bash_profile ~/.bash_profile
ln -sf cpanreporter/config.ini ~/.cpanreporter/config.ini
cp dataprinter ~/.dataprinter # Data::Printer doesn't like symlinks
chmod 700 ~/.dataprinter

ln -sf digrc ~/.digrc
ln -sf $LINK_FLAG dzil ~/.dzil
ln -sf gitignore_global ~/.gitignore_global
ln -sf minicpanrc ~/.minicpanrc
if [ $IS_MM = false ]; then
    ln -sf npmrc ~/.npmrc
fi
ln -sf perlcriticrc ~/.perlcriticrc
ln -sf perltidyrc ~/.perltidyrc
ln -sf profile ~/.profile
ln -sf proverc ~/.proverc
ln -sf psqlrc ~/.psqlrc
ln -sf re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf screenrc ~/.screenrc
ln -sf $LINK_FLAG sqitch ~/.sqitch
ln -sf tigrc ~/.tigrc
ln -sf Vagrantfile ~/.vagrant.d/Vagrantfile

popd

exit 0

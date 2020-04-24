#!/usr/bin/env bash

set -eu -o pipefail

# shellcheck source=../bash_functions.sh
source bash_functions.sh

PREFIX=~/dot-files

mkdir -p ~/.config/yamllint
mkdir -p ~/.cpanreporter
mkdir -p ~/.npm-packages
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d

ln -sf $PREFIX/ackrc ~/.ackrc
ln -sf $PREFIX/bashrc ~/.bashrc
ln -sf $PREFIX/bash_profile ~/.bash_profile
ln -sf $PREFIX/yamllint.yml ~/.config/yamllint/config
ln -sf $PREFIX/cpanreporter/config.ini ~/.cpanreporter/config.ini
cp $PREFIX/dataprinter ~/.dataprinter # Data::Printer doesn't like symlinks
chmod 700 ~/.dataprinter

ln -sf $PREFIX/digrc ~/.digrc
ln -sf $LINK_FLAG $PREFIX/dzil ~/.dzil
ln -sf $PREFIX/gitignore_global ~/.gitignore_global
ln -sf $PREFIX/golangci.yml ~/.golangci.yml
ln -sf $PREFIX/hammerspoon ~/.hammerspoon
ln -sf $PREFIX/minicpanrc ~/.minicpanrc
if [ $IS_MM = false ]; then
    ln -sf $PREFIX/npmrc ~/.npmrc
fi
ln -sf $PREFIX/perlcriticrc ~/.perlcriticrc
ln -sf $PREFIX/perltidyrc ~/.perltidyrc
ln -sf $PREFIX/profile ~/.profile
ln -sf $PREFIX/proverc ~/.proverc
ln -sf $PREFIX/psqlrc ~/.psqlrc
ln -sf $PREFIX/re.pl/repl.rc ~/.re.pl/repl.rc
ln -sf "$LINK_FLAG" $PREFIX/sqitch ~/.sqitch
ln -sf $PREFIX/sqliterc ~/.sqliterc
ln -sf $PREFIX/tigrc ~/.tigrc
ln -sf $PREFIX/Vagrantfile ~/.vagrant.d/Vagrantfile

exit 0

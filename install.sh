#!/usr/bin/env bash

set -eu -o pipefail

source ~/dot-files/bash_functions.sh

# https://stackoverflow.com/a/17072017/406224
if [ $IS_DARWIN = true ]; then
    # Install Net::SSLeay on MacOS
    export CPPFLAGS="-I/usr/local/opt/openssl/include"
    export LDFLAGS="-L/usr/local/opt/openssl/lib"

    if [ ! $(which brew) ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew config
    brew update
    brew bundle install --file=brew/defaults

    # These packages are installed because they are needed for the Linux tests.
    # It's not clear how to have them not be installed for MacOS on Travis
    if [[ $USER != 'travis' ]]; then
        brew bundle install --file=brew/local-only
        brew install vim -- --with-override-system-vi --without-perl

        if [[ -e ~/local-dot-files/Brewfile ]]; then
            brew bundle install --file=~/local-dot-files/Brewfile
        fi

        ./macos/dock.sh

        # Enable tap to click -- may require logout/login
        defaults -currentHost write -globalDomain com.apple.mouse.tapBehavior -int 1

    fi
fi

mkdir -p ~/.cpanreporter
mkdir -p ~/.re.pl
mkdir -p ~/.vagrant.d
mkdir -p ~/.npm-packages

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

git submodule init
git submodule update

./configure/git.sh

if [ $IS_MM = true ]; then
    git config --global --unset-all remote.origin.fetch
fi

./configure/ssh.sh

go get github.com/github/hub

# silence warnings when perlbrew not installed
mkdir -p $HOME/perl5/perlbrew/etc
touch $HOME/perl5/perlbrew/etc/bashrc

# deps for vim and fpp
./installer/pip.sh

./configure/vim.sh

./installer/fpp.sh

./configure/tmux.sh

NODE_MODULES='bash-language-server fkill-cli'

if [ $IS_DARWIN = false ]; then
    ./installer/linux.sh
fi

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

exit 0

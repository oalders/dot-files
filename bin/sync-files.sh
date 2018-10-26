#!/bin/bash

# If a machine can't fetch from github, we can copy stuff over from an installed set of dot files

if [ $# -eq 0 ]; then
    echo "Usage: sync-files.sh example.com"
    exit
fi

TARGET=$1

rsync -avz ~/dot-files $TARGET:~/
rsync -avz ~/.vim/plugged $TARGET:~/.vim/
rsync -avz ~/.vim/autoload $TARGET:~/.vim/
ssh $TARGET "touch ~/.local_vimrc"

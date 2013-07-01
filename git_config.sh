#!/bin/sh

# git config

echo "git config"

git config --global user.name "Olaf Alders"
git config --global user.email "olaf@wundersolutions.com"

git config --global color.ui "auto"
git config --global branch.master.remote origin
git config --global branch.master.merge refs/heads/master
git config --global branch.autosetuprebase always
git config --global push.default matching

git config --global alias.b  'branch'
git config --global alias.ba 'branch -a'
git config --global alias.changes 'diff --name-status -r'
git config --global alias.co 'checkout'
git config --global alias.delete-untracked-files 'clean -f -d'
git config --global alias.diffstat 'diff --stat -r'
git config --global alias.prom 'pull --rebase origin master'
git config --global alias.pt 'push --tags'
git config --global alias.st 'status'

# takes a commit name as sole arg
git config --global alias.whatis "show -s --pretty='tformat:%h (%s, %ad)' --date=short"


git config --global alias.flog 'log --stat --abbrev-commit --relative-date --pretty=oneline'
git config --global alias.plog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

#!/bin/sh

# git config

echo "git config"

git config --global user.name "Olaf Alders"
git config --global user.email "olaf@wundersolutions.com"

git config --global alias.b  'branch'
git config --global alias.ba 'branch -a'
git config --global alias.cam 'commit --amend'
git config --global alias.changes 'diff --name-status -r'
git config --global alias.ci 'commit'
git config --global alias.co 'checkout'
git config --global alias.dc 'diff --cached'
git config --global alias.delete-untracked-files 'clean -f -d'
git config --global alias.deleted 'log -1 --'
git config --global alias.diffstat 'diff --stat -r'
git config --global alias.dm 'diff -w -M master...HEAD'
git config --global alias.dom 'diff -w -M origin/master...HEAD'
git config --global alias.flog 'log --stat --abbrev-commit --relative-date --pretty=oneline'
git config --global alias.plog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global alias.prom 'pull --rebase origin master'
git config --global alias.pt 'push --tags'
git config --global alias.st 'status'
git config --global branch.autosetuprebase always
git config --global branch.master.merge refs/heads/master
git config --global color.ui "auto"
git config --global help.autocorrect 10
git config --global merge.conflictstyle diff3
git config --global push.default simple

# takes a commit name as sole arg
git config --global alias.whatis "show -s --pretty='tformat:%h (%s, %ad)' --date=short"



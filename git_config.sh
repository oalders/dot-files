#!/bin/sh

# git config

echo "git config"

git config --global user.email "olaf@wundersolutions.com"
git config --global user.name "Olaf Alders"

git config --global branch.autosetuprebase always
git config --global color.ui "auto"
git config --global github.user oalders
git config --global help.autocorrect 10
git config --global merge.conflictstyle diff3
git config --global push.default simple
git config --global rerere.enabled 1
git config --global --unset branch.master.merge

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
git config --global alias.doms 'diff -w -M origin/master...HEAD --stat'
git config --global alias.domo 'diff -w -M origin/master...HEAD --name-only'
git config --global alias.exec '!exec '
git config --global alias.flog 'log --stat --abbrev-commit --relative-date --pretty=oneline'
git config --global alias.from '!git fetch -p; git rebase origin/master'
git config --global alias.mylog 'log --author="Olaf Alders"'
git config --global alias.plog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global alias.prom 'pull --rebase origin master'
git config --global alias.pt 'push --tags'
git config --global alias.rc "rebase --continue"
git config --global alias.root "rev-parse --show-toplevel"
git config --global alias.st 'status'
git config --global alias.stu 'status --untracked-files=no'
git config --global alias.view-stash 'stash show -p stash@{0}'

# takes a commit name as sole arg
git config --global alias.whatis "show -s --pretty='tformat:%h (%s, %ad)' --date=short"

# for Facebook Path Picker (fpp)
git config --global grep.lineNumber true

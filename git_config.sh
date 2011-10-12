#!/bin/sh

# git config

echo "git config"

git config --global user.name "Olaf Alders"
git config --global user.email "olaf@wundersolutions.com"

git config --global color.ui true
git config --global branch.master.remote origin
git config --global branch.master.merge refs/heads/master
git config --global push.default matching

git config --global alias.ba 'branch -a'
git config --global alias.co 'checkout'
git config --global alias.s 'status'
git config --global alias.changes 'diff --name-status -r'
git config --global alias.diffstat 'diff --stat -r'
git config --global alias.pt 'push --tags'

# takes a commit name as sole arg
git config --global alias.whatis "show -s --pretty='tformat:%h (%s, %ad)' --date=short"

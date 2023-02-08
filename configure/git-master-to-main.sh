#!/usr/bin/env bash

# Converting master => main
# via https://www.kiloloco.com/articles/003-From-Master-To-Main/

#git checkout master
#git branch -m master main
git fetch
git branch --unset-upstream
git branch -u origin/main
#git push -u origin main
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

exit

# switch main branch in GH UI
git push origin --delete master
git branch -D master

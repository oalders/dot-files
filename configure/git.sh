#!/usr/bin/env bash

set -eu -o pipefail

echo "git config"

git config --global user.email "olaf@wundersolutions.com"
git config --global user.name "Olaf Alders"

git config --global --replace remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pull-requests/*"

git config --global branch.autosetuprebase always
git config --global branch.sort -committerdate

git config --global color.ui auto

git config --global column.ui auto

git config --global commit.verbose true

git config --global diff.algorithm histogram
git config --global diff.colorMoved true
git config --global diff.mnemonicPrefix true
git config --global diff.renames true

git config --global fetch.prune true
git config --global fetch.pruneTags true
git config --global fetch.all true

git config --global github.user oalders

git config --global help.autocorrect prompt

git config --global init.defaultBranch main

git config --global push.default simple
git config --global push.autoSetupRemote true
git config --global push.followTags true

git config --global rebase.autostash true
git config --global rebase.autosquash true
git config --global rebase.instructionFormat "(%an <%ae>) %s"

git config --global rerere.enabled true
git config --global rerere.autoupdate true

# git config --global tag.sort = version.refname

git config --global alias.auto-set-head 'remote set-head origin -a'
git config --global alias.b 'branch'
git config --global alias.ba 'branch -a'
git config --global alias.ca 'commit --amend'
git config --global alias.can 'commit --amend --no-edit'
git config --global alias.cap '!git can; git pf;'
git config --global alias.changes 'diff --name-status -r'
git config --global alias.ci 'commit'
git config --global alias.co 'checkout'
git config --global alias.dc 'diff --cached'
git config --global alias.delete-untracked-files 'clean -f -d'
git config --global alias.deleted 'log --diff-filter=D --'
git config --global alias.diffstat 'diff --stat -r'
git config --global alias.dm 'diff -w -M master...HEAD'
git config --global alias.dom 'diff -w -M origin/master...HEAD'
git config --global alias.doms 'diff -w -M origin/master...HEAD --stat'
git config --global alias.domo 'diff -w -M origin/master...HEAD --name-only'
git config --global alias.exec '!exec '
git config --global alias.flog 'log --stat --abbrev-commit --relative-date --pretty=oneline'
git config --global alias.from '!git fetch -p; git rebase origin/master'
git config --global alias.fromp '!git from; git pf'
git config --global alias.mylog 'log --author="Olaf Alders"'
git config --global alias.plog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global alias.prom 'pull --rebase origin master'
git config --global alias.pf 'push --force-with-lease'
git config --global alias.pt 'push --tags'
git config --global alias.rc "rebase --continue"
git config --global alias.rgrep "grep --recurse-submodules"

# Revert the changes introduced by a single file in a single commit
# Invoke as "git revert-file-in-commit path/to/file commit"
# which translates to:
# git show dedca812826 -- path/to/file | git apply -R
# shellcheck disable=SC2016
git config --global alias.revert-file-in-commit '!f() { git show $2 -- $1 | git apply -R;}; f'

git config --global alias.root "rev-parse --show-toplevel"
git config --global alias.st 'status'
git config --global alias.stu 'status --untracked-files=no'
git config --global alias.undo 'reset --soft HEAD^'
git config --global alias.view-stash 'stash show -p stash@{0}'

git config --global core.excludesfile ~/.gitignore_global

if is cli version git gte 2.35; then
    git config --global merge.conflictstyle zdiff3
else
    git config --global merge.conflictstyle diff3
fi

# Use Neovim with a 3 panes layout (LOCAL, MERGED and REMOTE)
# It is invoked at the command line via "git mergetool"
git mergetool --tool nvimdiff2

if is os id ne debian; then
    # configure delta as git's pager
    git config --global core.pager 'delta'
    git config --global delta.light false
    git config --global delta.navigate true
    git config --global diff.colorMoved default
    git config --global interactive.diffFilter 'delta --color-only'
else
    git config --global core.pager 'less'
fi

# takes a commit name as sole arg
git config --global alias.whatis "show -s --pretty='tformat:%h (%s, %ad)' --date=short"

git config --global grep.lineNumber true

git config --global grep.patternType perl

if [ -d '/Applications/Meld.app' ]; then
    echo "Setting Meld as mergetool"
    git config --global diff.tool 'meld'
    git config --global difftool.prompt false
    git config --global difftool.meld.trustExitCode true
    # shellcheck disable=SC2016
    git config --global difftool.meld.cmd 'open -W -a Meld --args "$LOCAL" "$PWD/$REMOTE"'
    git config --global merge.tool 'meld'
    git config --global mergetool.prompt false
    git config --global mergetool.meld.trustExitCode true
    # shellcheck disable=SC2016
    git config --global mergetool.meld.cmd 'open -W -a Meld --args --auto-merge "$PWD/$LOCAL" "$PWD/$BASE" "$PWD/$REMOTE" --output="$PWD/$MERGED"'
fi

# a "git config --unset" on something that isn't set but is a valid key returns with no
# message but an exit code of 5, which cause's bash's "set -e" to terminate both this
# script and the calling install script
set +e
git config --global --unset branch.master.merge

# shellcheck source=bash_functions.sh
source ~/dot-files/bash_functions.sh
# Requires git-lfs to have been installed
if ! is there git-lfs; then
    if is os name eq linux; then
        if is var IS_SUDOER eq true; then
            sudo apt-get install git-lfs || git lfs update --force
        fi
    fi
    git lfs install
fi

if is var IS_MM eq true; then
    git config --global --unset-all remote.origin.fetch
fi

exit 0

#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

alias python="python3"

# Reset PATH to keep it from being clobbered in tmux
# https://github.com/dmend/dotfiles/blob/master/.bash_profile#L3-L7
if [ -x /usr/libexec/path_helper ]; then
    # shellcheck disable=SC2123
    PATH=''
    . /etc/profile
fi

# Load .bashrc
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

add_path "$HOME/.plenv/bin"
if is there plenv; then
    eval "$(plenv init -)"
fi

if is there rbenv; then
    if [[ -d ~/.rbenv ]]; then
        add_path "$HOME/.rbenv/bin"
        eval "$(rbenv init -)"
    fi
fi

gcloud_completion="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
gcloud_bash="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"

# The next line updates PATH for the Google Cloud SDK.
if [ -f $gcloud_bash ]; then . $gcloud_bash; fi

# The next line enables shell command completion for gcloud.
if [ -f $gcloud_completion ]; then . $gcloud_completion; fi

GPG_TTY=$(tty)
export GPG_TTY

# Make MacOS less annoying
# Specifically don't run update_terminal_cwd()
export BASH_SILENCE_DEPRECATION_WARNING=1

# shellcheck disable=SC1091
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
fi

mkdir -p ~/.nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

. ~/dot-files/bash_functions.sh

if is os name eq darwin; then
    if is there brew; then
        HOMEBREW_PREFIX="$(brew --prefix)"
        # shellcheck disable=SC1090,SC1091
        if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
            source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
        else
            for completion in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
                [[ -r "$completion" ]] && source "$completion"
            done
        fi
    fi

    unset CLOUDSDK_PYTHON
    # Open command line in editor
    bind "\C-e":edit-and-execute-command

    # Apple silicon
    sqlite_path=/opt/homebrew/opt/sqlite3/bin
    if ! test -d $sqlite_path; then
        # Intel Macs
        version=$(ls /usr/local/Cellar/sqlite)
        sqlite_path="/usr/local/Cellar/sqlite/${version}/bin"
        if ! test -d "$sqlite_path"; then
            echo "$sqlite_path needs to be updated"
        fi
    fi
    add_path "$sqlite_path"
fi

if is os name ne darwin && is there fdfind; then
    alias fd="fdfind"
fi

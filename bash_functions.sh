# shellcheck shell=bash

# path handling
# http://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
add_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
    fi
}

remove_path() {
    PATH=$(tr : '\n' <<<"$PATH" | grep -v "^$1$" | paste -sd ':' -)
    export PATH
}

echo_path() {
    echo "path..."
    tr : '\n' <<<"$PATH"
}

clean_path() {
    # shellcheck disable=SC1001
    tr : '\n' <<<"$PATH" | awk '!x[$0]++' | grep \/ | grep -v game | paste -sd ":" -
}

reset_path() {
    PATH=$(clean_path)
    export PATH
}

if [[ ! "${MY_POSH_THEME:-}" ]]; then
    if test "${TMUX_PANE+x}"; then
        MY_POSH_THEME="tiny"
    elif test "${SSH_CLIENT+x}";then
        MY_POSH_THEME="jandedobbeleer"
    else
        MY_POSH_THEME="local"
    fi
fi

# posh handling
posh_me() {
    eval "$(oh-my-posh --init --shell bash --config ~/.config/oh-my-posh/themes/"${MY_POSH_THEME}".omp.json)"
}

toggle_posh() {
    if [[ $MY_POSH_THEME == "tiny" ]]; then
        MY_POSH_THEME="jandedobbeleer"
        posh_me
    else
        MY_POSH_THEME="tiny"
        posh_me
    fi
}

GO111MODULE=on
GOPATH=~/go
HAS_GO=false
add_path "/usr/local/go/bin"

if [[ (-n "${GOPATH+set}") && ($(command -v go version)) ]]; then
    HAS_GO=true
fi

HAS_PLENV=false

# should probably also ensure that Plenv version is not the system Perl
if [[ (-n "${PLENV_SHELL+set}") ]]; then
    HAS_PLENV=true
fi

IS_DARWIN=false
LINK_FLAG=""
PATH_ALIASES=\~/dot-files=@dots

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    IS_DARWIN=true
    LINK_FLAG="-hF"

    # A homebrew update of Python to > 3.8 has broken Google Cloud tools.
    CLOUDSDK_PYTHON=python2
    export CLOUDSDK_PYTHON

    # Not sure if this is needed in the longer term
    export TERM=xterm-256color

    alias vi="nvim"
    alias vim="nvim"

    PATH_ALIASES=\~/dot-files=@dots,\~/Documents/github=@gh,\~/Documents/github/oalders=@gho
elif [ "$(uname -s)" == "Linux" ]; then
    LINK_FLAG="-T"
fi

IS_GITHUB=false

LOOKS_LIKE_GITHUB=${GITHUB_WORKSPACE:-}
if [[ -n "$LOOKS_LIKE_GITHUB" ]]; then
    IS_GITHUB=true
fi

IS_MM=false
if [ -e /usr/local/bin/mm-perl ]; then
    IS_MM=true
    # Don't try to sudo on MM machines
    IS_SUDOER="${IS_SUDOER:=false}"
else
    IS_SUDOER="${IS_SUDOER:=false}"

    # The sudo -n gets misinterpreted by shellcheck
    # shellcheck disable=SC2143
    if [[ $(sudo -n true 2>&1 | grep 'password') ]]; then
        IS_SUDOER=false
    else
        IS_SUDOER=true
    fi
fi

tmux_version() {
    if [[ $(which tmux) ]]; then
        TMUX_VERSION=$(tmux -V | sed -En "s/^tmux[^0-9]*([.0-9]+).*/\1/p")
        export TMUX_VERSION
    fi
}

rename_tab() {
    if test "${TMUX_PANE+x}"; then
        echo -en "\033Ptmux;\033\033]0;$1\a\033\\"
    else
        echo -en "\033]0;$1\a"
    fi
}

HARNESS_OPTIONS="j1:c"

# Since ripgrep has no default config file location, we don't need to bother
# with symlinks.
RIPGREP_CONFIG_PATH=~/dot-files/ripgreprc

export GO111MODULE
export GOPATH
export HARNESS_OPTIONS
export HAS_GO
export HAS_PLENV
export IS_DARWIN
export IS_GITHUB
export IS_MM
export IS_SUDOER
export LINK_FLAG
export MY_POSH_THEME
export PATH_ALIASES
export RIPGREP_CONFIG_PATH

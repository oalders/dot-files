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

add_path "/usr/local/go/bin"
add_path "$HOME/local/bin"

detect_posh_settings() {
    MY_INSIDE_SSH=false
    MY_INSIDE_TMUX=false
    if test "${SSH_CLIENT+x}"; then
        MY_INSIDE_SSH=true
    fi
    if test "${TMUX_PANE+x}"; then
        MY_INSIDE_TMUX=true
    fi

    export MY_INSIDE_SSH
    export MY_INSIDE_TMUX
}

if [[ ! ${MY_POSH_THEME-} || ! ${FORCE_POSH_THEME-} ]]; then
    detect_posh_settings
    MY_POSH_THEME="remote"

    if [[ $MY_INSIDE_SSH == true ]]; then
        if [[ $MY_INSIDE_TMUX == true && ! ${FORCE_POSH_THEME-} ]]; then
            MY_POSH_THEME="remote-tiny"
        fi
    else
        MY_POSH_THEME="local"
        if [[ $MY_INSIDE_TMUX == true && ! ${FORCE_POSH_THEME-} ]]; then
            MY_POSH_THEME="local-tiny"
        fi
    fi
fi

# posh handling
posh_me() {
    eval "$(oh-my-posh prompt init bash --config ~/.config/oh-my-posh/themes/"${MY_POSH_THEME}".omp.json)"
}

toggle_posh() {
    detect_posh_settings
    if [[ $MY_POSH_THEME == "local" ]]; then
        MY_POSH_THEME="local-tiny"
    elif [[ $MY_POSH_THEME == "local-tiny" ]]; then
        MY_POSH_THEME="local"
    elif [[ $MY_POSH_THEME == "remote" ]]; then
        MY_POSH_THEME="remote-tiny"
    elif [[ $MY_POSH_THEME == "remote-tiny" ]]; then
        MY_POSH_THEME="remote"
    else
        MY_POSH_THEME="remote"
    fi

    FORCE_POSH_THEME=true
    export FORCE_POSH_THEME

    posh_me
}

GO111MODULE=on
GOPATH=~/go
HAS_PLENV=false

# should probably also ensure that Plenv version is not the system Perl
if [[ -n ${PLENV_SHELL+set} ]]; then
    HAS_PLENV=true
fi

IS_DARWIN=false
LINK_FLAG=""
PATH_ALIASES=\~/dot-files=@dots

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    IS_DARWIN=true
    LINK_FLAG="-hF"

    # Not sure if this is needed in the longer term
    export TERM=xterm-256color

    alias vi="nvim"
    alias vim="nvim"

    PATH_ALIASES=\~/dot-files=@dots,\~/Documents/github=@gh,\~/Documents/github/oalders=@gho
elif [ "$(uname -s)" == "Linux" ]; then
    LINK_FLAG="-T"
fi

IS_GITHUB=false

LOOKS_LIKE_GITHUB=${GITHUB_WORKSPACE-}
if [[ -n $LOOKS_LIKE_GITHUB ]]; then
    IS_GITHUB=true
fi

if [[ -z ${IS_MM+x} ]]; then
    if [[ -e /usr/local/bin/mm-perl ]]; then
        IS_MM=true
    else
        IS_MM=false
    fi
fi

if [[ -z ${IS_SUDOER+x} ]]; then
    if [[ $IS_MM == true ]]; then
        # Don't try to sudo on MM machines
        IS_SUDOER="${IS_SUDOER:=false}"

    else
        # The sudo -n gets misinterpreted by shellcheck
        # shellcheck disable=SC2143
        if [[ $(sudo -n true 2>&1 | grep 'password') ]]; then
            IS_SUDOER=false
        else
            IS_SUDOER=true
        fi
    fi
fi

rename_tab() {
    if test "${TMUX_PANE+x}"; then
        echo -en "\033Ptmux;\033\033]0;$1\a\033\\"
    else
        echo -en "\033]0;$1\a"
    fi
}

# https://stackoverflow.com/questions/9783507/how-can-i-check-in-my-bashrc-if-an-alias-was-already-set
# remove this in future
[ "$(type -t ll)" = "alias" ] && unalias ll

# shellcheck disable=SC2002
ll() {
    SELECTION=$(cat ~/dot-files/launch.txt | fzf --reverse --no-multi)
    COMMAND=$(echo "$SELECTION" | cut -d'#' -f2-)

    echo "Running $COMMAND"
    eval "$COMMAND"
}

format_json() {
    FILE=$1
    jq <"$FILE" | sed 's/\\n/\n/g' | sed 's/\\t/\t/g'
}

HARNESS_OPTIONS="j1:c"

# Since ripgrep has no default config file location, we don't need to bother
# with symlinks.
RIPGREP_CONFIG_PATH=~/dot-files/ripgreprc

if [[ $(command -v nproc) ]]; then
    MY_PROCS="$(nproc)"
    export MY_PROCS
fi

ghrc() {
    REPO=$1
    if [[ $(trurl --verify "$REPO") ]]; then
        URL=$(trurl --verify "$REPO" --get '{path}')

        CLONE_TO=$(echo "$URL" | sed 's/^\///' | sed 's/\.git$//')

        gh repo clone "$REPO" "$CLONE_TO"
        cd "$CLONE_TO" || echo "Could not chdir to $CLONE_TO"
    fi
}

change_git_origin() {
    # https://github.com/metacpan/metacpan-api.git
    # git@github.com:metacpan/metacpan-api.git

    REPO=$(git config --get remote.origin.url)

    TO=$(trurl "$REPO" --get '{path}' | sed 's/^\///' | sed 's/\.git$//')

    GIT="git@github.com:${TO}.git"

    git remote remove origin
    git remote add origin "$GIT"
}

export GO111MODULE
export GOPATH
export HARNESS_OPTIONS
export HAS_PLENV
export IS_DARWIN
export IS_GITHUB
export IS_MM
export IS_SUDOER
export LINK_FLAG
export MY_POSH_THEME
export PATH_ALIASES
export RIPGREP_CONFIG_PATH

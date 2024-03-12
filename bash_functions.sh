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
    inside_ssh=false
    MY_INSIDE_TMUX=false
    if test "${SSH_CLIENT+x}"; then
        inside_ssh=true
    fi
    if test "${TMUX_PANE+x}"; then
        MY_INSIDE_TMUX=true
    fi

    export MY_INSIDE_TMUX
}

if [[ ! ${posh_theme-} || ! ${FORCE_POSH_THEME-} ]]; then
    detect_posh_settings
    posh_theme="remote"

    if [[ $inside_ssh == true ]]; then
        if [[ $MY_INSIDE_TMUX == true && ! ${FORCE_POSH_THEME-} ]]; then
            posh_theme="remote-tiny"
        fi
    else
        posh_theme="local"
        if [[ $MY_INSIDE_TMUX == true && ! ${FORCE_POSH_THEME-} ]]; then
            posh_theme="local-tiny"
        fi
    fi
fi

# posh handling
posh_me() {
    eval "$(oh-my-posh prompt init bash --config ~/.config/oh-my-posh/themes/"${posh_theme}".omp.json)"
}

toggle_posh() {
    detect_posh_settings
    if [[ $posh_theme == "local" ]]; then
        posh_theme="local-tiny"
    elif [[ $posh_theme == "local-tiny" ]]; then
        posh_theme="local"
    elif [[ $posh_theme == "remote" ]]; then
        posh_theme="remote-tiny"
    elif [[ $posh_theme == "remote-tiny" ]]; then
        posh_theme="remote"
    else
        posh_theme="remote"
    fi

    FORCE_POSH_THEME=true
    export FORCE_POSH_THEME

    posh_me
}

GO111MODULE=on
GOPATH=~/go
LINK_FLAG=""
PATH_ALIASES=\~/dot-files=@dots

if is os name eq darwin; then
    LINK_FLAG="-hF"

    # Not sure if this is needed in the longer term
    export TERM=xterm-256color

    alias vi="nvim"
    alias vim="nvim"

    PATH_ALIASES=\~/dot-files=@dots,\~/Documents/github=@gh,\~/Documents/github/oalders=@gho
elif is os name eq linux; then
    LINK_FLAG="-T"
fi

IS_GITHUB=false

LOOKS_LIKE_GITHUB=${GITHUB_WORKSPACE-}
if [[ -n $LOOKS_LIKE_GITHUB ]]; then
    IS_GITHUB=true
fi

if [[ ! ${IS_MM-} ]]; then
    if [[ -e /usr/local/bin/mm-perl ]]; then
        IS_MM=true
    else
        IS_MM=false
    fi
fi

if [[ ! ${IS_SUDOER-} ]]; then
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
    selection=$(nl -n rz -w2 -s' ' ~/dot-files/launch.txt | fzf --reverse --no-multi)
    command=$(echo "$selection" | cut -d' ' -f2-)

    echo "Running $command"
    eval "$command"
}

format_json() {
    file=$1
    jq <"$file" | sed 's/\\n/\n/g' | sed 's/\\t/\t/g'
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
    repo=$1
    if [[ $(trurl --verify "$repo") ]]; then
        url=$(trurl --verify "$repo" --get '{path}')

        clone_to=$(echo "$url" | sed 's/^\///' | sed 's/\.git$//')

        gh repo clone "$repo" "$clone_to"
        cd "$clone_to" || echo "Could not chdir to $clone_to"
    fi
}

change_git_origin() {
    # https://github.com/metacpan/metacpan-api.git
    # git@github.com:metacpan/metacpan-api.git

    repo=$(git config --get remote.origin.url)

    to=$(trurl "$repo" --get '{path}' | sed 's/^\///' | sed 's/\.git$//')

    git="git@github.com:${to}.git"

    git remote remove origin
    git remote add origin "$git"
}

tmux_session_name() {
    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    padding=60

    if [ "$inside_git_repo" ]; then

        branch=$(git rev-parse --abbrev-ref HEAD)
        current_dir=${PWD##*/}
        current_dir=$(printf "%-20s" "$current_dir")

        prefix='⁉️ '
        if [[ ${PWD##*/} == 'dot-files' ]] || [[ ${PWD##*/} == 'local-dot-files' ]]; then
            prefix='🔵'
        elif [[ -f 'dist.ini' ]] || [[ -f 'cpanfile' ]] || [[ -f 'app.psgi' ]]; then
            prefix='🐪'
        elif [[ -f 'Cargo.toml' ]]; then
            prefix='🦀'
        elif [[ -f 'go.mod' ]]; then
            prefix='🚦'
        elif [[ -f 'tsconfig.json' ]] || [[ -f '.npmignore' ]]; then
            prefix='☕'
        elif [[ -d 'ftplugin' ]]; then
            prefix='🔌'
        elif [[ -f 'Dockerfile' ]] || [[ -f 'docker-compose.yml' ]]; then
            prefix='🐳'
        fi
        SESSION_NAME="$prefix $current_dir  $branch"
    else
        SESSION_NAME=$(pwd)
        strip="$HOME/"
        SESSION_NAME=${SESSION_NAME/$strip/}
        padding=58
    fi

    # A "." will produce a "bad session name" error
    SESSION_NAME=${SESSION_NAME//./-}
    SESSION_NAME=${SESSION_NAME//oalders/OA}
    SESSION_NAME=$(printf "%-${padding}s" "$SESSION_NAME")
    export SESSION_NAME
}

export GO111MODULE
export GOPATH
export HARNESS_OPTIONS
export IS_GITHUB
export IS_MM
export IS_SUDOER
export LINK_FLAG
export RIPGREP_CONFIG_PATH

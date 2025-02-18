# shellcheck shell=bash

# path handling
# http://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
add_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1:$PATH"
        export PATH
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
    if [[ $MY_INSIDE_TMUX == true && ! ${FORCE_POSH_THEME-} ]]; then
        export TINY_POSH=1
    fi
fi

# posh handling
posh_me() {
    eval "$(oh-my-posh prompt init bash --config ~/.config/oh-my-posh/themes/local.omp.json)"
}

toggle_posh() {
    detect_posh_settings
    if [[ -n $TINY_POSH ]]; then
        unset TINY_POSH
    else
        export TINY_POSH=1
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
if is var GITHUB_WORKSPACE set; then
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
    file=~/dot-files/launch.txt

    # The `nl` command is used for numbering lines in a file. The `-n rz`
    # option formats the line number to have leading zeros. The `-w2` option
    # sets the width of the line number field to 2 characters. The `-s' '`
    # option sets the separator between the line numbers and the text to a
    # space. `$file` is the file to be numbered.
    selection=$(nl -n rz -w2 -s' ' $file | fzf --reverse --no-multi)
    command=$(echo "$selection" | awk -F'# ' '{print $2}')

    echo "Running $command"
    history -s "$command"
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
        current_dir=$(printf "%-18s" "$current_dir")

        declare -A fileToPrefix=(
            #perl
            ["app.psgi"]=""
            ["cpanfile"]=""
            ["dist.ini"]=""

            # rust
            ["Cargo.toml"]=""

            # docker
            ["docker-compose.yml"]="󰡨"
            ["Dockerfile"]="󰡨"

            # configuration
            ["dot-files"]=""
            ["local-dot-files"]=""

            # markdown -- nvim devicons doesn't have an icon for hugo
            ["freelancer-theme"]="󰍔"
            ["www-olafalders-dot-com"]="󰍔"

            # neovim plugin
            ["ftplugin"]="🔌"

            # go
            ["go.mod"]=""

            # typescript
            [".npmignore"]=""
            ["tsconfig.json"]=""

            # node
            ["package.json"]=""
        )

        # We can't preserve the order of the keys in associative array above
        keys=(
            "dot-files"
            "local-dot-files"
            "www-olafalders-dot-com"
            "dist.ini"
            "cpanfile"
            "app.psgi"
            "Cargo.toml"
            "go.mod"
            "tsconfig.json"
            ".npmignore"
            "ftplugin"
            "Dockerfile"
            "docker-compose.yml"
            "package.json"
            "freelancer-theme"
        )

        prefix='⁉️'
        topDir=''
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            mainCheckoutDir=$(git rev-parse --git-common-dir)
            if [[ $mainCheckoutDir != ".git" ]]; then
                parentDir=$(dirname "$mainCheckoutDir")
                topDir=$(basename "$parentDir")
            fi
        fi
        if [[ ! $topDir ]]; then
            topDir=$(basename "$PWD")
        fi
        for file in "${keys[@]}"; do
            if [[ $topDir == "$file" ]] || [[ -f $file ]]; then
                prefix="${fileToPrefix[$file]}"
                break
            fi
        done
        SESSION_NAME="$prefix  $current_dir   $branch"
    else
        SESSION_NAME=$(pwd)
        strip="$HOME/"
        SESSION_NAME=${SESSION_NAME/$strip/}
        padding=58
    fi

    # A "." will produce a "bad session name" error
    SESSION_NAME=${SESSION_NAME//./-}
    SESSION_NAME=${SESSION_NAME//oalders/OA}
    export SESSION_NAME
}

db() {
    if [ $# -lt 3 ]; then
        echo "🤬 Not enough arguments provided. Usage: debounce 6 h something"
        return
    fi

    # exit as early as possible if we can't create the cache dir
    # test -d appears to be slightly faster (3ms?) than mkdir -p
    cache_dir=~/.cache/debounce
    test -d $cache_dir || mkdir -p $cache_dir

    number=$1
    units=$2
    shift 2

    # everything remaining is runnable
    target="$*"

    # file is $target with slashes converted to dashes
    file=$(echo "$target" | tr / -)

    debounce="$cache_dir/$file"

    if [ -f "$debounce" ] && is fso age "$debounce" lt "$number" "$units"; then
        echo "🚥 will not run $target more than once every $number $units"
        return
    fi

    "$@" && touch "$debounce"
}

function clone_or_update_repo() {
    local dir="$1"
    local repo="$2"
    local src="$HOME/dot-files/src"

    mkdir -p "$src"
    cd "$src" || exit 1

    if [[ -d $dir ]]; then
        git -C "$dir" pull --rebase
    else
        git clone "$repo" "$dir"
    fi
}

export GO111MODULE
export GOPATH
export HARNESS_OPTIONS
export IS_GITHUB
export IS_MM
export IS_SUDOER
export LINK_FLAG
export RIPGREP_CONFIG_PATH

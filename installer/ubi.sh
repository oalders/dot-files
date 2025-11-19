#!/usr/bin/env bash

set -eu

in="$HOME/local/bin"

# shellcheck source=path_functions.sh
source ~/dot-files/path_functions.sh

test -d "$in" || mkdir -p "$in"
add_path "$in"

# set -x

# Simplified debounce function for bootstrapping (before "is" is available)
# Hardcoded to check if file is older than 1 day
db() {
    if [ $# -lt 1 ]; then
        echo "🤬 Not enough arguments provided. Usage: db something"
        return
    fi

    # exit as early as possible if we can't create the cache dir
    # test -d appears to be slightly faster (3ms?) than mkdir -p
    cache_dir=~/.cache/debounce
    test -d $cache_dir || mkdir -p $cache_dir

    # everything is runnable
    target="$*"

    # file is $target with slashes converted to dashes
    file=$(echo "$target" | tr / -)

    debounce="$cache_dir/$file"

    # Check if file exists and is less than 1 day old
    if [ -f "$debounce" ] && find "$debounce" -mtime -1 2>/dev/null | grep -q .; then
        echo "🚥 will not run $target more than once per day"
        return
    fi

    "$@" && touch "$debounce"
}

# can't use "is" here as we may not yet have it
if [[ ! "$(command -v curl)" && "$(command -v apt-get)" ]]; then
    if [[ ! "$(command -v sudo)" ]]; then
        apt-get update && apt-get install sudo --autoremove -y
    fi
    sudo apt-get install curl --autoremove -y
fi

maybe_install() {
    project="$1"
    shift
    db ubi --project "$project" --in "$in" "$@"
}

if [ ! -f "$in/ubi" ]; then
    curl --silent --location \
        https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh |
        TARGET=$in sh
else
    db "$in/ubi" --self-upgrade
fi

# there's a bit of a bootstrapping issue here, so we'll use the bash function
# to debounce debounce
db ubi --project oalders/debounce --in "$in"

maybe_install air-verse/air
maybe_install atanunq/viu
maybe_install bensadeh/tailspin --exe tspin
maybe_install charmbracelet/gum
maybe_install cloudflare/cloudflared
maybe_install crate-ci/typos
maybe_install golangci/golangci-lint
maybe_install houseabsolute/omegasort
maybe_install houseabsolute/precious
maybe_install jesseduffield/lazydocker
maybe_install jesseduffield/lazygit
maybe_install jqlang/jq
maybe_install junegunn/fzf
maybe_install kubernetes-sigs/kustomize
maybe_install mgdm/htmlq
maybe_install oalders/is
maybe_install stripe/stripe-cli --exe stripe
maybe_install tummychow/git-absorb

if is cli output stdout hostname eq wolfblitzer; then
    delta_version=0.16.5
    if is cli version delta ne $delta_version; then
        ubi --url https://github.com/dandavison/delta/releases/download/${delta_version}/git-delta_${delta_version}_amd64.deb --in /tmp/ubi
        sudo dpkg -i /tmp/ubi/delta
    fi
elif is os name eq darwin; then
    maybe_install dandavison/delta
else
    maybe_install dandavison/delta --matching musl
    maybe_install eza-community/eza
fi

if is os name eq darwin; then
    if ! is there bat || is cli version bat ne 0.24.0; then
        ubi --in "$in" \
            --url https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-apple-darwin.tar.gz
    fi
else
    maybe_install sharkdp/bat
fi

maybe_install cli/cli --exe gh

url=https://raw.githubusercontent.com/junegunn/fzf/refs/heads/master/bin/fzf-tmux
target="$HOME/local/bin/fzf-tmux"

if ! is there fzf-tmux; then
    curl -o "$target" "$url"
    chmod 755 "$target"
fi

if is os id eq almalinux; then
    exit
fi

if is there gh && ! gh extension list | grep --quiet copilot; then
    gh extension install github/gh-copilot || true
fi

if is there gh && ! gh extension list | grep --quiet gh-dash; then
    db gh extension install dlvhdr/gh-dash || true
fi

# ensure is completions are up to date
# shellcheck disable=SC2016
db bash -c 'eval "$(is install-completions)"'

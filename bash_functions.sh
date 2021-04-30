# shellcheck shell=bash

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

# https://stackoverflow.com/a/17072017/406224
if [ "$(uname)" == "Darwin" ]; then
    IS_DARWIN=true
    LINK_FLAG="-hF"

    # A homebrew update of Python to > 3.8 has broken Google Cloud tools.
    CLOUDSDK_PYTHON=python2
    export CLOUDSDK_PYTHON

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

if [[ $IS_DARWIN = true ]]; then
    HARNESS_OPTIONS="j$(sysctl -n hw.logicalcpu):c"
elif [[ $IS_MM = false ]]; then
    HARNESS_OPTIONS="j$(nproc):c"
else
    HARNESS_OPTIONS="j1:c"
fi

# Since ripgrep has no default config file location, we don't need to bother
# with symlinks.
RIPGREP_CONFIG_PATH=~/dot-files/ripgreprc

export GOPATH
export GO111MODULE
export HARNESS_OPTIONS
export HAS_GO
export HAS_PLENV
export IS_DARWIN
export IS_GITHUB
export IS_MM
export IS_SUDOER
export LINK_FLAG
export RIPGREP_CONFIG_PATH
